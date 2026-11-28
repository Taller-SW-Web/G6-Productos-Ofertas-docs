# Seguridad y CD

Se detectaron en Backend `cd-services-azure.yml`, `publish-only-images.yml`, `ci.yml` y otros workflows; Frontend usa CI y verificación Vercel. No se disparó `workflow_dispatch`, tag, release ni deploy. Los checks de seguridad BE/FE y protecciones de rama no se validaron para un nuevo HEAD; **NOT_RUN**. FE #101 Draft permanece independiente. Todo push de los PR candidatos debe revisarse por trigger antes de ejecutarse; si dispara CD o preview automático que cambie el entorno vigente, se conserva rama local sin push.

La compilación y tests APIM L0 no acreditan SAST/SCA/SBOM/secret scanning ni un gate G7 negativo completo. `SEC-BE-01`, `FESEC-01` y `SEC-CD-01` permanecen parciales hasta CI de SHA exacto y revisión de hallazgos.
