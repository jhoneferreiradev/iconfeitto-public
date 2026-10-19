package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.estoque.item;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Embeddable;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Transient;
import lombok.*;

import java.util.Set;
import java.util.UUID;

@Embeddable
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@Data
@NoArgsConstructor
public class DadosFichaTecnica {

    @Setter(AccessLevel.NONE)
    @Transient
    @EqualsAndHashCode.Include
    private String uid = UUID.randomUUID().toString();

    private boolean possuiFichaTecnica;
    private int tempoPreparoMinutos;
    private int rendimentoReceita;

    @OneToMany(mappedBy = "itemPrincipal", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<ItemFichaTecnica> itens;

    public DadosFichaTecnica(boolean possuiFichaTecnica, int tempoPreparoMinutos, int rendimentoReceita,
                             Set<ItemFichaTecnica> itens) {
        this.possuiFichaTecnica = possuiFichaTecnica;
        this.tempoPreparoMinutos = tempoPreparoMinutos;
        this.rendimentoReceita = rendimentoReceita;
        this.itens = itens;
    }
}
