/// Data de uma operação (compra, venda, fabricação) com o horário do registro.
///
/// O usuário escolhe apenas o dia; o sistema completa com hora, minuto,
/// segundo e milissegundo do momento em que a operação é salva. Assim, as
/// movimentações de estoque ficam em ordem de lançamento mesmo no mesmo dia.
///
/// Ao editar uma operação e manter o mesmo dia, o horário original é preservado
/// para não mudar a posição dela na ordem das movimentações.
DateTime dataComHorarioDeRegistro(DateTime escolhida, {DateTime? original}) {
  if (original != null &&
      original.year == escolhida.year &&
      original.month == escolhida.month &&
      original.day == escolhida.day) {
    return original;
  }
  final agora = DateTime.now();
  return DateTime(
    escolhida.year,
    escolhida.month,
    escolhida.day,
    agora.hour,
    agora.minute,
    agora.second,
    agora.millisecond,
  );
}
