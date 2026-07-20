import '../models/procurement_detail.dart';
import '../models/procurement_process.dart';

abstract interface class ProcurementRepository {
  Future<List<ProcurementProcess>> buscarProcesos(String palabraClave);

  Future<ProcurementDetail> obtenerDetalle(String ocid);
}
