# MK-001 Bulk HTTP performance artifacts

This folder preserves the raw CSV/JSON profiles emitted by `apps/bulk-svc/test/bulk-http-benchmark.e2e-spec.ts`.

| Variant | Source SHA | Files |
|---|---|---|
| Baseline | `c73ed61c533a21787d1dab22aa79cd83ff77da14` | `baseline-bulk-http-profile.csv`, `baseline-bulk-http-profile.json` |
| Candidate | `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660` | `candidate-bulk-http-profile.csv`, `candidate-bulk-http-profile.json` |

The concurrent admission/retry and Gateway security evidence from the pre-continuation Backend HEAD `49bab9e2075819d922c63b06fcc6fc6ac16ce703` is preserved at [`bulk-catalog-retry-local-2026-11-24-base-49bab9e.json`](../bulk-catalog-retry-local-2026-11-24-base-49bab9e.json). It contains 6/6 executed local tests on PostgreSQL 17. It predates the two additional Gateway negative tests in PR #274 and must not be presented as their result.

The official PR #274 artifact for HEAD `0cc83cfe1e928214f08581cb62aaa06599b53578` is preserved at [`bulk-catalog-gateway-supabase-ci-pr274-2026-11-24.json`](../bulk-catalog-gateway-supabase-ci-pr274-2026-11-24.json): 8/8 tests passed, zero skipped, run `45482639358`. It validates PostgreSQL 17, local Supabase Storage CLI 3.4.0 with a private disposable bucket, Gateway/JWKS, concurrent Bulk admission/retry and Catalog handler delivery. It does not validate Azure Service Bus.

Each JSON records three concurrency windows (1, 8, 32), 1,000 multipart admissions each after 10 warmups, request/response byte accounting, p50/p95/p99, throughput, failures/timeouts, SQL calls, PostgreSQL shared buffers, pool observations and RabbitMQ queue depth. It identifies the composition as a Nest `TestingModule` HTTP listener, isolated PostgreSQL 17, real isolated RabbitMQ, and loopback private-Storage HTTP fixture. It is not a production `dist/main` process and Storage is not Supabase. Multipart framing is not included in client request-byte instrumentation. PostgreSQL outage/recovery has a separate E2E test.

The profiles report no failure or timeout for both variants. The results are mixed across concurrency, so they do not establish a global performance improvement. The profile does not exercise Azure Service Bus Basic, APIM, G7 grants, XLSX maximum sizes, or a shared environment. There is no agreed SLA threshold attached to this measurement.

To rerun from a checkout of either source SHA with Docker, configure the variant and SHA explicitly, enable the benchmark, and select an output directory:

```powershell
$env:G6_PERFORMANCE_HTTP='1'
$env:G6_PERFORMANCE_VARIANT='baseline' # use candidate for the candidate SHA
$env:G6_PERFORMANCE_SHA='c73ed61c533a21787d1dab22aa79cd83ff77da14'
$env:G6_PERFORMANCE_OUTPUT='.ci/performance-baseline'
npm run test:e2e -- apps/bulk-svc/test/bulk-http-benchmark.e2e-spec.ts
```

For the candidate run, use SHA `af5a6b4e0e7f4cc7a5d32fcf3694d19cb6db9660`, variant `candidate`, and a separate output directory. The test requires Docker and creates disposable PostgreSQL 17 and RabbitMQ containers; do not point it to shared services. Compare only runs with matching source, host, Docker resources, and test setup.
