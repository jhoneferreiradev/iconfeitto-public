package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.BandeiraCartaoControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
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
public class BandeiraCartaoController implements BandeiraCartaoControllerDoc {

    @Autowired
    private BandeiraCartaoService bandeiraCartaoService;

    @Transactional
    @PostMapping
    public ResponseEntity<BandeiraCartaoDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) BandeiraCartaoDTOEntrada dtoNovaBandeiraCartao) {
        BandeiraCartao bandeiraCartao = ConversorObjetos.converter(dtoNovaBandeiraCartao, BandeiraCartaoDTOEntrada.class, BandeiraCartao.class);
        bandeiraCartao = bandeiraCartaoService.salvar(bandeiraCartao);
        BandeiraCartaoDTOSaida saida = ConversorObjetos.converter(bandeiraCartao, BandeiraCartao.class, BandeiraCartaoDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping
    public ResponseEntity<List<BandeiraCartaoDTOSaida>> listar() {
        List<BandeiraCartao> bandeirasCartoes = bandeiraCartaoService.listarTodos();
        List<BandeiraCartaoDTOSaida> saidas = bandeirasCartoes.stream().map(bandeiraCartao -> ConversorObjetos.converter(bandeiraCartao, BandeiraCartao.class, BandeiraCartaoDTOSaida.class)).toList();
        return ResponseEntity.ok(saidas);
    }

    @GetMapping("/{id}")
    public ResponseEntity<BandeiraCartaoDTOSaida> buscarPorId(@PathVariable Long id) {
        BandeiraCartao bandeiraCartao = bandeiraCartaoService.getPorId(id);
        BandeiraCartaoDTOSaida saida = ConversorObjetos.converter(bandeiraCartao, BandeiraCartao.class, BandeiraCartaoDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<BandeiraCartaoDTOSaida> atualizar(@PathVariable Long id, @RequestBody BandeiraCartaoDTOEntrada dtoAtualizacao) {
        BandeiraCartao bandeiraCartaoExistente = bandeiraCartaoService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(dtoAtualizacao, bandeiraCartaoExistente);

        BandeiraCartao bandeiraCartaoAtualizada = bandeiraCartaoService.salvar(bandeiraCartaoExistente);
        BandeiraCartaoDTOSaida saida = ConversorObjetos.converter(bandeiraCartaoAtualizada, BandeiraCartao.class, BandeiraCartaoDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

}
