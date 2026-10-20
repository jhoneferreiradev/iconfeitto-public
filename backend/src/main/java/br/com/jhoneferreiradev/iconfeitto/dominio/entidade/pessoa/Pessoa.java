package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadePadraoAtivavelComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_pessoa")
@Inheritance(strategy = InheritanceType.JOINED)
@DiscriminatorColumn(name = "tipo_pessoa", discriminatorType = DiscriminatorType.STRING)
@NoArgsConstructor
public abstract class Pessoa extends EntidadePadraoAtivavelComConfeitaria {

    @Enumerated(EnumType.STRING)
    private PersonalidadeJuridica personalidadeJuridica;
    private String nome;
    @Enumerated(EnumType.STRING)
    @Column(name = "tipo_pessoa", insertable = false, updatable = false)
    private TipoPessoa tipoPessoa;

    public Pessoa(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, boolean ativo,
                  PersonalidadeJuridica personalidadeJuridica, String nome, TipoPessoa tipoPessoa) {
        super(id, confeitaria, criadoEm, ativo);
        this.personalidadeJuridica = personalidadeJuridica;
        this.nome = nome;
        this.tipoPessoa = tipoPessoa;
    }
}
