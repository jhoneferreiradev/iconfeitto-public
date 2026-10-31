package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda;

import java.util.Set;

public enum StatusVenda {
    PEDIDO("Pedido"),
    EM_PRODUCAO("Em Produção"),
    AGUARDANDO_RETIRADA("Aguardando retirada"),
    SAIU_PARA_ENTREGA("Saiu para entrega"),
    ENTREGUE("Entregue"),
    CANCELADA("Cancelada");

    private final String descricao;

    StatusVenda(String descricao) {
        this.descricao = descricao;
    }

    public String getDescricao() {
        return descricao;
    }

    public boolean naoMovimentaEstoque() {
        return !movimentaEstoque();
    }

    public boolean movimentaEstoque() {
        return statusQueMovimentamEstoque().contains(this);
    }

    private Set<StatusVenda> statusQueMovimentamEstoque() {
        return Set.of(
                SAIU_PARA_ENTREGA,
                ENTREGUE
        );
    }

}
