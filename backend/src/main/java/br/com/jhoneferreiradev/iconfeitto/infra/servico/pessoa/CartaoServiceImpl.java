package br.com.jhoneferreiradev.iconfeitto.infra.servico.pessoa;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.cartao.Cartao;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.pessoa.CartaoRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.CartaoService;
import br.com.jhoneferreiradev.iconfeitto.infra.servico.base.BaseServiceImpl;
import org.springframework.stereotype.Service;

@Service
public class CartaoServiceImpl extends BaseServiceImpl<Cartao> implements CartaoService {

    public CartaoServiceImpl(CartaoRepository repository) {
        super(repository, "Cartao");
    }

}
