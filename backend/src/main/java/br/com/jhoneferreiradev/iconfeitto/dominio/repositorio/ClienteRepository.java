package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cliente.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ClienteRepository extends JpaRepository<Cliente, Long> {
}
