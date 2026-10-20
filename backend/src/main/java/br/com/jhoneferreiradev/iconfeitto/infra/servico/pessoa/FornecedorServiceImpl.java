package br.com.jhoneferreiradev.iconfeitto.infra.servico.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.fornecedor.Fornecedor;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.pessoa.FornecedorRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.FornecedorService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class FornecedorServiceImpl extends BaseServiceImpl<Fornecedor> implements FornecedorService {

    public FornecedorServiceImpl(FornecedorRepository repository) {
        super(repository, "Fornecedor");
    }

}
