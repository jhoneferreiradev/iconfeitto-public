package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.BandeiraCartaoControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.BandeiraCartaoDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.BandeiraCartaoDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.bandeiracartao.BandeiraCartao;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.BandeiraCartaoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/bandeiras-cartoes")
public class BandeiraCartaoController
        extends ControllerBase<BandeiraCartao, BandeiraCartaoDTOSaida, BandeiraCartaoDTOEntrada>
        implements BandeiraCartaoControllerDoc {

    @Autowired
    public BandeiraCartaoController(BandeiraCartaoService bandeiraCartaoService) {
        super(bandeiraCartaoService, BandeiraCartao.class, BandeiraCartaoDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<BandeiraCartaoDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) BandeiraCartaoDTOEntrada dto) {
        return super.adicionar(dto);
    }

    @GetMapping
    public ResponseEntity<List<BandeiraCartaoDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<BandeiraCartaoDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<BandeiraCartaoDTOSaida> atualizar(@PathVariable Long id, @RequestBody BandeiraCartaoDTOEntrada dto) {
        return super.atualizar(id, dto);
    }

}
