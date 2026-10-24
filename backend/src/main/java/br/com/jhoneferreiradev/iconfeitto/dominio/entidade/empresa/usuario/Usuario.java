package br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.usuario;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadePadraoAtivavelComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import org.jspecify.annotations.Nullable;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.List;

@EqualsAndHashCode(callSuper = true, onlyExplicitlyIncluded = true)
@Data
@Entity
@Table(name = "tb_usuario")
@NoArgsConstructor
public class Usuario extends EntidadePadraoAtivavelComConfeitaria implements UserDetails {

    @EqualsAndHashCode.Include
    private String email;

    private String nome;

    @Enumerated(EnumType.STRING)
    private PerfilUsuario perfil;

    public Usuario(Long id, Confeitaria confeitaria,
                   OffsetDateTime criadoEm, boolean ativo,
                   String email, String nome, PerfilUsuario perfil) {
        super(id, confeitaria, criadoEm, ativo);
        this.email = email;
        this.nome = nome;
        this.perfil = perfil;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_USER"));
    }

    @Override
    public @Nullable String getPassword() {
        return email;
    }

    @Override
    public String getUsername() {
        return email;
    }
}
