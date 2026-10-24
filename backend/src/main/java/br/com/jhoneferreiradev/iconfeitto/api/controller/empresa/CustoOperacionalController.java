package br.com.jhoneferreiradev.iconfeitto.api.controller.empresa;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.empresa.CustoOperacionalControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.custooperacional.CustoOperacionalDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.empresa.custooperacional.CustoOperacionalDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.CustoOperacional;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.custooperacinoal.CustoOperacionalService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/custos-operacionais")
public class CustoOperacionalController implements CustoOperacionalControllerDoc {

    @Autowired
    private CustoOperacionalService custoOperacionalService;

    @Transactional
    @PostMapping
    public ResponseEntity<CustoOperacionalDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) CustoOperacionalDTOEntrada dto) {
        CustoOperacional custo = ConversorObjetos.converter(dto, CustoOperacionalDTOEntrada.class, CustoOperacional.class);
        custo = custoOperacionalService.salvar(custo);
        CustoOperacionalDTOSaida saida = ConversorObjetos.converter(custo, CustoOperacional.class, CustoOperacionalDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping
    public ResponseEntity<List<CustoOperacionalDTOSaida>> listar() {
        final List<CustoOperacional> lista = custoOperacionalService.listarTodos();
        List<CustoOperacionalDTOSaida> saidas = lista
                .stream()
                .map(custo ->
                        ConversorObjetos.converter(custo, CustoOperacional.class, CustoOperacionalDTOSaida.class)).toList();
        return ResponseEntity.ok(saidas);
    }

    @GetMapping("/{id}")
    public ResponseEntity<CustoOperacionalDTOSaida> buscarPorId(@PathVariable Long id) {
        CustoOperacional custo = custoOperacionalService.getPorId(id);
        CustoOperacionalDTOSaida saida = ConversorObjetos.converter(custo, CustoOperacional.class, CustoOperacionalDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<CustoOperacionalDTOSaida> atualizar(@PathVariable Long id, @RequestBody CustoOperacionalDTOEntrada dtoAtualizacao) {
        CustoOperacional custoExistente = custoOperacionalService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(dtoAtualizacao, custoExistente);

        custoExistente = custoOperacionalService.salvar(custoExistente);

        CustoOperacionalDTOSaida saida = ConversorObjetos.converter(custoExistente, CustoOperacional.class, CustoOperacionalDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> remover(@PathVariable Long id) {
        custoOperacionalService.remover(id);
        return ResponseEntity.noContent().build();
    }
}
