package br.com.jhoneferreiradev.iconfeitto.dominio.repositorio;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.fornecedor.Fornecedor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FornecedorRepository extends JpaRepository<Fornecedor, Long> {
}
