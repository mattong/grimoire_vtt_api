# Backend CORS Configuration

> **Date:** 2026-06-01
> **Status:** Design (pre-implementation)
> **Version:** 0.6.0-alpha target

**Goal:** Enable cross-origin requests from the Vite dev server (`http://localhost:5173`) so the frontend SPA can communicate with the Rails API during development.

---

## Change: Enable `rack-cors`

The `rack-cors` gem is already in the Gemfile but commented out:

```ruby
# Gemfile line 36
gem "rack-cors"
```

Uncomment it and run `bundle install`.

---

## Create Initializer

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization']
  end
end
```

**Key detail:** `expose: ['Authorization']` is required because the auth endpoints return the JWT in the `Authorization` response header. Without this header being exposed, the frontend's `fetch` cannot read it.

---

## Production

For production, the `origins` list would be updated to the actual frontend domain(s). This can be environment-specific:

```ruby
origins ENV.fetch('CORS_ORIGINS', 'http://localhost:5173').split(',')
```

---

## Testing

- Start the Rails server and frontend dev server
- Attempt a login from the frontend and verify the response includes the `Authorization` header
- Verify that `GET /api/games` from the frontend succeeds (proves CORS is functional)
