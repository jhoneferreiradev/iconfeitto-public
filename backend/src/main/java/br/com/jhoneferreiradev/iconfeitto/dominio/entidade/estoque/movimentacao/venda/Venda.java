package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.venda;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.ItemMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.MovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.movimentacao.TipoMovimentacaoEstoque;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cliente.Cliente;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_venda")
@DiscriminatorValue("01") // 01 = TipoMovimentacaoEstoque.VENDA.getId()
@PrimaryKeyJoinColumn(name = "id")
@NoArgsConstructor
public class Venda extends MovimentacaoEstoque {

    private OffsetDateTime data;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cliente_id")
    private Cliente cliente;

    @OneToMany(mappedBy = "movimentacaoEstoque", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemMovimentacaoEstoque> itens;

    public Venda(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, OffsetDateTime data,
                 TipoMovimentacaoEstoque tipoMovimentacao, OffsetDateTime data1, Cliente cliente,
                 Set<ItemMovimentacaoEstoque> itens) {
        super(id, confeitaria, criadoEm, data, tipoMovimentacao);
        this.data = data1;
        this.cliente = cliente;
        this.itens = itens;
    }
}
