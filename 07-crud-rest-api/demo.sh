#!/bin/bash
# CompTIA AutoOps+ | How CRUD Works in REST APIs
# Exam Objective 2.3 — RESTful CRUD: GET, POST, PUT, PATCH, DELETE, curl, response codes
#
# Uses jsonplaceholder.typicode.com — a free public REST API, no auth required.
# REQUIRES: internet connection


# ===========================================================================
# BLOCK 0 — What is CRUD?
#
# CRUD maps directly to HTTP methods:
#   CREATE  -> POST
#   READ    -> GET
#   UPDATE  -> PUT (replace entire resource) or PATCH (partial update)
#   DELETE  -> DELETE
#
# curl flags used throughout:
#   -s               : silent mode (no progress bar)
#   -X <METHOD>      : specify the HTTP method
#   -H "..."         : add a request header
#   -d '...'         : send a request body
#   -w "\nStatus: %{http_code}\n" : print the HTTP status code after the response
# ===========================================================================

echo "=== API base URL: https://jsonplaceholder.typicode.com ==="
echo ""


# ===========================================================================
# BLOCK 1 — READ (GET)
#
# GET retrieves data. It is read-only — no data is changed on the server.
# Response code 200 = OK
# ===========================================================================

echo "--- GET a single post (READ) ---"
curl -s https://jsonplaceholder.typicode.com/posts/1 \
  -w "\nStatus: %{http_code}\n"


# ===========================================================================
# BLOCK 2 — CREATE (POST)
#
# POST sends a new resource to the server.
# The body contains the data in JSON format.
# Response code 201 = Created
# ===========================================================================

echo ""
echo "--- POST a new post (CREATE) ---"
curl -s -X POST https://jsonplaceholder.typicode.com/posts \
  -H "Content-Type: application/json" \
  -d '{"title": "My New Post", "body": "Hello from CompTIA AutoOps+", "userId": 1}' \
  -w "\nStatus: %{http_code}\n"


# ===========================================================================
# BLOCK 3 — FULL UPDATE (PUT)
#
# PUT replaces the ENTIRE resource with the data you send.
# If you leave a field out of the body, it is gone.
# Response code 200 = OK
# ===========================================================================

echo ""
echo "--- PUT post 1 (FULL UPDATE — replaces everything) ---"
curl -s -X PUT https://jsonplaceholder.typicode.com/posts/1 \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "title": "Completely Replaced Title", "body": "Completely replaced body", "userId": 1}' \
  -w "\nStatus: %{http_code}\n"


# ===========================================================================
# BLOCK 4 — PARTIAL UPDATE (PATCH)
#
# PATCH updates only the fields you send. Everything else stays the same.
# This is the key difference from PUT.
# Response code 200 = OK
# ===========================================================================

echo ""
echo "--- PATCH post 1 (PARTIAL UPDATE — only changes title) ---"
curl -s -X PATCH https://jsonplaceholder.typicode.com/posts/1 \
  -H "Content-Type: application/json" \
  -d '{"title": "Just the Title Changed"}' \
  -w "\nStatus: %{http_code}\n"


# ===========================================================================
# BLOCK 5 — DELETE
#
# DELETE removes the resource. The response body is usually empty.
# Response code 200 or 204 = success (204 = No Content)
# ===========================================================================

echo ""
echo "--- DELETE post 1 ---"
curl -s -X DELETE https://jsonplaceholder.typicode.com/posts/1 \
  -w "\nStatus: %{http_code}\n"


# ===========================================================================
# BLOCK 6 — Error response codes
#
# 2xx = success     (200 OK, 201 Created, 204 No Content)
# 3xx = redirect    (301 Moved, 302 Found)
# 4xx = client error (400 Bad Request, 401 Unauthorized, 404 Not Found)
# 5xx = server error (500 Internal Server Error, 503 Service Unavailable)
# ===========================================================================

echo ""
echo "--- GET a resource that does not exist (404) ---"
curl -s https://jsonplaceholder.typicode.com/posts/99999 \
  -w "\nStatus: %{http_code}\n"
