from __future__ import annotations

import hashlib
import unittest
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]


class G6ApprovalGovernanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.openapi = yaml.safe_load((ROOT / "contratos/http/openapi.yaml").read_text(encoding="utf-8"))
        cls.asyncapi = yaml.safe_load((ROOT / "contratos/eventos/asyncapi.yaml").read_text(encoding="utf-8"))

    def test_acta_and_matrix_are_indexed_from_decisions_and_h5(self):
        acta = ROOT / "arquitectura/decisiones/ACTA-APROBACION-INTERNA-G6-H5-2026-11-22.md"
        matrix = ROOT / "arquitectura/decisiones/MATRIZ-APROBACIONES-Y-DEPENDENCIAS-G6-H5.md"
        self.assertTrue(acta.is_file())
        self.assertTrue(matrix.is_file())
        acta_text = acta.read_text(encoding="utf-8")
        self.assertIn("APPROVED_G6", acta_text)
        self.assertIn("22/11/2026", acta_text)
        self.assertIn("America/Lima", acta_text)
        self.assertIn("4404b7c7d3cd9254ddc6932532ab3a9ba1a52f78", acta_text)
        for document in (ROOT / "README.md", ROOT / "hitos/h5/README.md", ROOT / "arquitectura/decisiones/REGISTRO_DEC_F.md"):
            self.assertIn("ACTA-APROBACION-INTERNA-G6-H5-2026-11-22.md", document.read_text(encoding="utf-8"))

    def test_bulk_retry_approval_metadata_matches_without_marking_runtime_pass(self):
        self.assertEqual(self.openapi["info"]["version"], "0.7.0-rc.3")
        self.assertEqual(self.asyncapi["info"]["version"], "0.7.0-rc.3")
        self.assertEqual(self.openapi["x-g6-approval-status"], "APPROVED_G6")
        self.assertEqual(self.asyncapi["x-g6-approval-status"], "APPROVED_G6")
        reconciliation = self.openapi["paths"]["/carga-masiva/productos/importaciones/por-correlacion/{correlationId}"]["get"]
        self.assertEqual(reconciliation["x-contract-status"], "APPROVED_G6")
        self.assertEqual(reconciliation["x-g6-approval-status"], "APPROVED_G6")
        for message_name in ("CatalogBulkUpsertRequestedV4", "CatalogBulkUpsertCompletedV2", "CatalogBulkUpsertRejectedV2"):
            message = self.asyncapi["components"]["messages"][message_name]
            self.assertEqual(message["x-contract-status"], "APPROVED_G6")
            self.assertEqual(message["x-g6-approval-status"], "APPROVED_G6")
            self.assertEqual(message["x-runtime-status"], "PENDIENTE_IMPLEMENTACION")

    def test_covered_current_contracts_have_no_internal_approval_pending_label(self):
        current = (
            ROOT / "integraciones/BULK_RETRY_V1_PROPUESTA_CONTRACTUAL.md",
            ROOT / "integraciones/COBERTURA-CONTRACTUAL-MK001-MK016-H5.md",
            ROOT / "contratos/http/openapi.yaml",
            ROOT / "contratos/eventos/asyncapi.yaml",
        )
        for path in current:
            content = path.read_text(encoding="utf-8")
            self.assertNotIn("PROPOSED_NOT_APPROVED", content, str(path))
            self.assertNotIn("PENDIENTE_APROBACION_G6", content, str(path))
        matrix = (ROOT / "arquitectura/decisiones/MATRIZ-APROBACIONES-Y-DEPENDENCIAS-G6-H5.md").read_text(encoding="utf-8")
        for status in ("PENDIENTE_HOMOLOGACION_EXTERNA", "PENDIENTE_GRANT_G7", "PENDIENTE_INFRAESTRUCTURA", "PENDIENTE_EVIDENCIA", "PENDIENTE_IMPLEMENTACION"):
            self.assertIn(status, matrix)
        self.assertIn("RESERVADO_NO_APLICA_BULK_V2", matrix)
        self.assertIn("IMPLEMENTACION", matrix.upper())

    def test_h4_snapshots_still_match_their_recorded_hashes(self):
        sums = ROOT / "contratos/historico/h4/SHA256SUMS"
        for line in sums.read_text(encoding="utf-8").splitlines():
            expected, relative_path = line.split(maxsplit=1)
            file_path = ROOT / relative_path.strip()
            actual = hashlib.sha256(file_path.read_bytes()).hexdigest()
            self.assertEqual(actual, expected, relative_path)


if __name__ == "__main__":
    unittest.main()
