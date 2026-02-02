/**
 * CloudFront Function for Landing Page
 * Handles viewer request events
 */

function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith("/")) {
    request.uri = uri + "index.html";
    return request;
  }

  if (!uri.includes(".") && !uri.startsWith("/api")) {
    request.uri = uri + "/index.html";
  }

  return request;
}
