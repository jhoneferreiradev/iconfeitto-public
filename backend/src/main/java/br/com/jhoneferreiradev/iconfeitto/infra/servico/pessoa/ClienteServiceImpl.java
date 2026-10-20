package br.com.jhoneferreiradev.iconfeitto.infra.servico.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cliente.Cliente;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.pessoa.ClienteRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.ClienteService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class ClienteServiceImpl extends BaseServiceImpl<Cliente> implements ClienteService {

    public ClienteServiceImpl(ClienteRepository repository) {
        super(repository, "Cliente");
    }

}
