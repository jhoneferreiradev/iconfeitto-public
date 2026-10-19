package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao;

import lombok.Getter;

public enum TipoMovimentacaoEstoque {
    COMPRA("00", SentidoTipoMovimentacaoEstoque.ENTRADA),
    VENDA("01", SentidoTipoMovimentacaoEstoque.SAIDA),
    FABRICACAO("02", SentidoTipoMovimentacaoEstoque.SAIDA),
    SAIDA_CONSUMO("03", SentidoTipoMovimentacaoEstoque.SAIDA),
    AJUSTE_ENTRADA("04", SentidoTipoMovimentacaoEstoque.ENTRADA),
    AJUSTE_SAIDA("05", SentidoTipoMovimentacaoEstoque.SAIDA);

    @Getter
    private final String id;
    @Getter
    private final SentidoTipoMovimentacaoEstoque sentido;

    TipoMovimentacaoEstoque(String id, SentidoTipoMovimentacaoEstoque sentido) {
        this.id = id;
        this.sentido = sentido;
    }
}
