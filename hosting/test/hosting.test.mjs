// Checks what Firebase Hosting serves for deep links (#41): the two .well-known
// files, their content type, and the /invite/<token> fallback page.
// Run: node --test 'hosting/test/*.test.mjs'   (no dependencies)
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const hosting = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const repo = path.resolve(hosting, "..");
const config = JSON.parse(readFileSync(path.join(hosting, "firebase.json"), "utf8")).hosting;
const publicDir = path.join(hosting, config.public);
const readPublic = (p) => readFileSync(path.join(publicDir, p), "utf8");

// The app identifiers come from the native projects, so the files can't drift from them.
const iosBundleId = readFileSync(path.join(repo, "app/ios/Runner.xcodeproj/project.pbxproj"), "utf8")
  .match(/PRODUCT_BUNDLE_IDENTIFIER = ([\w.]+);/)[1];
const androidAppId = readFileSync(path.join(repo, "app/android/app/build.gradle.kts"), "utf8")
  .match(/applicationId = "([\w.]+)"/)[1];

// Firebase Hosting glob: ** matches across slashes, * within one segment.
const globToRegExp = (glob) =>
  new RegExp(
    "^" +
      glob
        .replace(/[.+^${}()|[\]\\]/g, "\\$&")
        .replace(/\*\*/g, "\u0000")
        .replace(/\*/g, "[^/]*")
        .replace(/\u0000/g, ".*") +
      "$",
  );
const headersFor = (url) =>
  Object.fromEntries(
    config.headers
      .filter((h) => globToRegExp(h.source).test(url))
      .flatMap((h) => h.headers.map(({ key, value }) => [key.toLowerCase(), value])),
  );
// What Hosting serves for a URL: a static file wins over rewrites, first matching rewrite next.
const served = (url) => {
  if (existsSync(path.join(publicDir, url))) return { file: url };
  const rewrite = config.rewrites.find((r) => globToRegExp(r.source).test(url));
  return rewrite ?? null;
};

test("apple-app-site-association is JSON served as application/json", () => {
  const url = "/.well-known/apple-app-site-association";
  assert.deepEqual(served(url), { file: url });
  JSON.parse(readPublic(url));
  assert.equal(headersFor(url)["content-type"], "application/json");
});

test("apple-app-site-association opens /invite/* and /join/* in the iOS app", () => {
  const aasa = JSON.parse(readPublic("/.well-known/apple-app-site-association"));
  const [detail] = aasa.applinks.details;
  assert.equal(aasa.applinks.details.length, 1);
  assert.equal(detail.appIDs.length, 1);
  assert.match(detail.appIDs[0], new RegExp(`^[A-Z0-9_]+\\.${iosBundleId.replace(/\./g, "\\.")}$`));
  assert.deepEqual(
    detail.components.map((c) => c["/"]),
    ["/invite/*", "/join/*"],
  );
});

test("assetlinks.json is JSON served as application/json", () => {
  const url = "/.well-known/assetlinks.json";
  assert.deepEqual(served(url), { file: url });
  JSON.parse(readPublic(url));
  assert.equal(headersFor(url)["content-type"], "application/json");
});

test("assetlinks.json lets the Android app handle links on this domain", () => {
  const links = JSON.parse(readPublic("/.well-known/assetlinks.json"));
  assert.equal(links.length, 1);
  assert.deepEqual(links[0].relation, ["delegate_permission/common.handle_all_urls"]);
  assert.equal(links[0].target.namespace, "android_app");
  assert.equal(links[0].target.package_name, androidAppId);
  assert.ok(links[0].target.sha256_cert_fingerprints.length >= 1);
});

test("/invite/<token> serves the store fallback page, not the API", () => {
  const target = served("/invite/abc123");
  assert.ok(target?.destination, "no rewrite for /invite/<token>");
  const page = readPublic(target.destination);
  assert.match(page, /<html/i);
  assert.match(page, /apps\.apple\.com/);
  assert.match(page, /play\.google\.com\/store\/apps\/details\?id=/);
  assert.ok(page.includes(androidAppId), "Play Store link must point at the app's package");
  assert.equal(served("/api/v1/lists")?.run?.serviceId, "cesta-backend");
});

test("/invite/<token> is never cached, so a token isn't kept at the edge", () => {
  assert.match(headersFor("/invite/abc123")["cache-control"] ?? "", /no-store/);
});
