package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ItemMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.MovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.TipoMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cliente.Cliente;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_venda")
@DiscriminatorValue("VENDA") // 01 = TipoMovimentacaoEstoque.VENDA.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class Venda extends MovimentacaoEstoque {

    private OffsetDateTime dataVenda;
    private OffsetDateTime dataPrevisaoEntrega;
    private OffsetDateTime dataEntrega;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cliente_id")
    private Cliente cliente;

    @Enumerated(EnumType.STRING)
    private StatusVenda statusVenda;

    @Enumerated(EnumType.STRING)
    private TipoVenda tipoVenda;

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public Venda(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, TipoMovimentacaoEstoque tipoMovimentacao,
                 OffsetDateTime dataVenda, OffsetDateTime dataPrevisaoEntrega, OffsetDateTime dataEntrega,
                 Cliente cliente, StatusVenda statusVenda, TipoVenda tipoVenda, Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, tipoMovimentacao);
        this.dataVenda = dataVenda;
        this.dataPrevisaoEntrega = dataPrevisaoEntrega;
        this.dataEntrega = dataEntrega;
        this.cliente = cliente;
        this.statusVenda = statusVenda;
        this.tipoVenda = tipoVenda;
        this.itens = itens;
    }

    @Override
    public Optional<OffsetDateTime> getDataMovimentacao() {
        if (tipoVenda == TipoVenda.PRONTA_ENTREGA) {
            return Optional.ofNullable(dataVenda);
        } else {
            return Optional.ofNullable(dataEntrega);
        }
    }
}
