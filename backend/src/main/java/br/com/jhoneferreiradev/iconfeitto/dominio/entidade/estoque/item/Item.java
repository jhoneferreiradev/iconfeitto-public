package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item;

import br.com.jhoneferreiradev.iconfeitto.dominio.EntidadePadraoAtivavelComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria.Confeitaria;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_item")
@NoArgsConstructor
public class Item extends EntidadePadraoAtivavelComConfeitaria {

    @EqualsAndHashCode.Include
    private String nome;

    @EqualsAndHashCode.Include
    @Enumerated(EnumType.STRING)
    private TipoItem tipoItem;

    @Embedded
    private DadosEstoque dadosEstoque;

    @Embedded
    private DadosFichaTecnica dadosFichaTecnica;

    @Embedded
    private DadosCusto dadosCusto;

    @OneToMany(mappedBy = "item", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<PrecoItem> precosDeVenda;

    public Item(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, boolean ativo, String nome,
                TipoItem tipoItem, DadosEstoque dadosEstoque, DadosFichaTecnica dadosFichaTecnica,
                DadosCusto dadosCusto, Set<PrecoItem> precosDeVenda) {
        super(id, confeitaria, criadoEm, ativo);
        this.nome = nome;
        this.tipoItem = tipoItem;
        this.dadosEstoque = dadosEstoque;
        this.dadosFichaTecnica = dadosFichaTecnica;
        this.dadosCusto = dadosCusto;
        this.precosDeVenda = precosDeVenda;
    }
}
