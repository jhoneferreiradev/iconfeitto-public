package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao;

import lombok.Getter;

public enum TipoMovimentacaoEstoque {
    COMPRA(SentidoTipoMovimentacaoEstoque.ENTRADA),
    VENDA(SentidoTipoMovimentacaoEstoque.SAIDA),
    FABRICACAO(SentidoTipoMovimentacaoEstoque.SAIDA),
    SAIDA_CONSUMO(SentidoTipoMovimentacaoEstoque.SAIDA),
    AJUSTE_ENTRADA(SentidoTipoMovimentacaoEstoque.ENTRADA),
    AJUSTE_SAIDA(SentidoTipoMovimentacaoEstoque.SAIDA);

    @Getter
    private final SentidoTipoMovimentacaoEstoque sentido;

    TipoMovimentacaoEstoque(SentidoTipoMovimentacaoEstoque sentido) {
        this.sentido = sentido;
    }
}
