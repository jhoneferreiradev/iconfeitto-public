package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.usuario;

import br.com.jhoneferreiradev.iconfeitto.dominio.EntidadeBaseComDadosPadraoComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.confeitaria.Confeitaria;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_usuario")
@NoArgsConstructor
public class Usuario extends EntidadeBaseComDadosPadraoComConfeitaria {

    @EqualsAndHashCode.Include
    private String email;

    private String nome;

    private String tokenExterno;

    @Enumerated(EnumType.STRING)
    private PerfilUsuario perfil;

    public Usuario(Long id, Confeitaria confeitaria, OffsetDateTime criadoEm, String email, String nome,
                   String tokenExterno, PerfilUsuario perfil) {
        super(id, confeitaria, criadoEm);
        this.email = email;
        this.nome = nome;
        this.tokenExterno = tokenExterno;
        this.perfil = perfil;
    }
}
