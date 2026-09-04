const {randomUUID} = require("node:crypto");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {
  S3Client,
  CreateMultipartUploadCommand,
  UploadPartCommand,
  CompleteMultipartUploadCommand,
  AbortMultipartUploadCommand,
  GetObjectCommand,
  DeleteObjectCommand,
  HeadObjectCommand,
} = require("@aws-sdk/client-s3");
const {getSignedUrl} = require("@aws-sdk/s3-request-presigner");

initializeApp();

const accountId = defineSecret("R2_ACCOUNT_ID");
const accessKeyId = defineSecret("R2_ACCESS_KEY_ID");
const secretAccessKey = defineSecret("R2_SECRET_ACCESS_KEY");
const bucketName = defineSecret("R2_BUCKET");
const secrets = [accountId, accessKeyId, secretAccessKey, bucketName];
const region = "us-central1";
const maxVideoSize = 5 * 1024 * 1024 * 1024;

function r2() {
  return new S3Client({
    region: "auto",
    endpoint: `https://${accountId.value()}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: accessKeyId.value(),
      secretAccessKey: secretAccessKey.value(),
    },
  });
}

function requireAuth(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Authentication required.");
  return request.auth.uid;
}

async function requireAdmin(request) {
  const uid = requireAuth(request);
  const snapshot = await getFirestore().collection("users").doc(uid).get();
  const role = String(snapshot.data()?.role || "").toLowerCase();
  if (role !== "admin" && role !== "администратор") {
    throw new HttpsError("permission-denied", "Administrator role required.");
  }
  return uid;
}

function text(value, field, max = 500) {
  if (typeof value !== "string" || !value.trim() || value.length > max) {
    throw new HttpsError("invalid-argument", `Invalid ${field}.`);
  }
  return value.trim();
}

function videoKey(fileName) {
  const safeName = text(fileName, "fileName", 255).replace(/[^a-zA-Z0-9._-]/g, "_");
  const extension = safeName.includes(".") ? safeName.split(".").pop().toLowerCase() : "mp4";
  if (!["mp4", "m4v", "mov", "webm"].includes(extension)) {
    throw new HttpsError("invalid-argument", "Unsupported video format.");
  }
  return `videos/${new Date().toISOString().slice(0, 10)}/${randomUUID()}.${extension}`;
}

function existingVideoPath(value) {
  const path = text(value, "videoPath", 1024);
  if (!path.startsWith("videos/") || path.includes("..")) {
    throw new HttpsError("invalid-argument", "Invalid video path.");
  }
  return path;
}

exports.r2StartMultipartUpload = onCall({region, secrets}, async (request) => {
  const uid = await requireAdmin(request);
  const fileName = text(request.data?.fileName, "fileName", 255);
  const contentType = text(request.data?.contentType, "contentType", 100);
  const size = Number(request.data?.size);
  if (!contentType.startsWith("video/") || !Number.isSafeInteger(size) || size <= 0 || size > maxVideoSize) {
    throw new HttpsError("invalid-argument", "Video must be between 1 byte and 5 GiB.");
  }
  const key = videoKey(fileName);
  const result = await r2().send(new CreateMultipartUploadCommand({
    Bucket: bucketName.value(), Key: key, ContentType: contentType,
    Metadata: {uploadedBy: uid, originalName: encodeURIComponent(fileName)},
  }));
  return {uploadId: result.UploadId, videoPath: key, fileName, size, contentType};
});

exports.r2SignUploadPart = onCall({region, secrets}, async (request) => {
  await requireAdmin(request);
  const uploadId = text(request.data?.uploadId, "uploadId", 1000);
  const videoPath = existingVideoPath(request.data?.videoPath);
  const partNumber = Number(request.data?.partNumber);
  if (!Number.isInteger(partNumber) || partNumber < 1 || partNumber > 10000) {
    throw new HttpsError("invalid-argument", "Invalid part number.");
  }
  const command = new UploadPartCommand({
    Bucket: bucketName.value(), Key: videoPath, UploadId: uploadId, PartNumber: partNumber,
  });
  return {url: await getSignedUrl(r2(), command, {expiresIn: 15 * 60})};
});

exports.r2CompleteMultipartUpload = onCall({region, secrets}, async (request) => {
  await requireAdmin(request);
  const uploadId = text(request.data?.uploadId, "uploadId", 1000);
  const videoPath = existingVideoPath(request.data?.videoPath);
  const parts = request.data?.parts;
  if (!Array.isArray(parts) || parts.length === 0 || parts.length > 10000) {
    throw new HttpsError("invalid-argument", "Invalid multipart manifest.");
  }
  const normalized = parts.map((part, index) => ({
    ETag: text(part?.etag, "etag", 200),
    PartNumber: Number(part?.partNumber || index + 1),
  }));
  await r2().send(new CompleteMultipartUploadCommand({
    Bucket: bucketName.value(), Key: videoPath, UploadId: uploadId,
    MultipartUpload: {Parts: normalized},
  }));
  const head = await r2().send(new HeadObjectCommand({Bucket: bucketName.value(), Key: videoPath}));
  return {videoPath, size: Number(head.ContentLength || 0), contentType: head.ContentType || "video/mp4"};
});

exports.r2AbortMultipartUpload = onCall({region, secrets}, async (request) => {
  await requireAdmin(request);
  await r2().send(new AbortMultipartUploadCommand({
    Bucket: bucketName.value(),
    Key: existingVideoPath(request.data?.videoPath),
    UploadId: text(request.data?.uploadId, "uploadId", 1000),
  }));
  return {ok: true};
});

exports.r2GetPlaybackUrl = onCall({region, secrets}, async (request) => {
  requireAuth(request);
  const videoPath = existingVideoPath(request.data?.videoPath);
  const url = await getSignedUrl(r2(), new GetObjectCommand({
    Bucket: bucketName.value(), Key: videoPath,
  }), {expiresIn: 60 * 60});
  return {url, expiresIn: 3600};
});

exports.r2GetVideoInfo = onCall({region, secrets}, async (request) => {
  requireAuth(request);
  const videoPath = existingVideoPath(request.data?.videoPath);
  const head = await r2().send(new HeadObjectCommand({Bucket: bucketName.value(), Key: videoPath}));
  return {
    videoPath,
    size: Number(head.ContentLength || 0),
    contentType: head.ContentType || "application/octet-stream",
    etag: head.ETag || null,
    updatedAt: head.LastModified?.toISOString() || null,
  };
});

exports.r2DeleteVideo = onCall({region, secrets}, async (request) => {
  await requireAdmin(request);
  const videoPath = existingVideoPath(request.data?.videoPath);
  await r2().send(new DeleteObjectCommand({Bucket: bucketName.value(), Key: videoPath}));
  return {ok: true};
});
