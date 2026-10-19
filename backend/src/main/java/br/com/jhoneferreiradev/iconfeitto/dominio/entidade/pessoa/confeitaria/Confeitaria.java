package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria;

import br.com.jhoneferreiradev.iconfeitto.dominio.EntidadeBaseComDataCriacao;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.PersonalidadeJuridica;
import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.Set;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_confeitaria")
@NoArgsConstructor
public class Confeitaria extends EntidadeBaseComDataCriacao {

    @EqualsAndHashCode.Include
    private String nome;

    @EqualsAndHashCode.Include
    @Enumerated(EnumType.STRING)
    private PersonalidadeJuridica personalidadeJuridica;

    @EqualsAndHashCode.Include
    private String documento;

    private String endereco;

    private String telefone;

    private String facebook;

    private String instagram;

    @OneToMany(mappedBy = "confeitaria", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<CustoOperacional> custosOperacionais;

    public Confeitaria(Long id, OffsetDateTime criadoEm, String nome, PersonalidadeJuridica personalidadeJuridica, String documento,
                       String endereco, String telefone, String facebook, String instagram,
                       Set<CustoOperacional> custosOperacionais) {
        super(id, criadoEm);
        this.nome = nome;
        this.personalidadeJuridica = personalidadeJuridica;
        this.documento = documento;
        this.endereco = endereco;
        this.telefone = telefone;
        this.facebook = facebook;
        this.instagram = instagram;
        this.custosOperacionais = custosOperacionais;
    }

}
