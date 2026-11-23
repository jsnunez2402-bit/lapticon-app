String _dos(int n) => n.toString().padLeft(2, '0');

/// 2026-12-01 (formato que espera el backend en fechaViaje).
String fechaIso(DateTime d) => '${d.year}-${_dos(d.month)}-${_dos(d.day)}';

/// 01/12/2026. Las fechas del backend llegan en UTC (medianoche), así que se
/// muestran en UTC para no "retroceder" un día en Colombia (UTC-5).
String fmtFecha(DateTime? d) {
  if (d == null) return '—';
  final u = d.toUtc();
  return '${_dos(u.day)}/${_dos(u.month)}/${u.year}';
}

/// Hora local hh:mm para los mensajes del chat.
String fmtHora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';

DateTime? parseFecha(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

/// Minúsculas y sin tildes, para comparar nombres de ciudades.
String normalizar(String s) {
  const con = 'áéíóúüñÁÉÍÓÚÜÑ';
  const sin = 'aeiouunaeiouun';
  final b = StringBuffer();
  for (final ch in s.trim().split('')) {
    final i = con.indexOf(ch);
    b.write(i >= 0 ? sin[i] : ch);
  }
  return b.toString().toLowerCase();
}
