package br.com.jhoneferreiradev.iconfeitto.api.controller.empresa;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.empresa.CustoOperacionalControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
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
public class CustoOperacionalController
        extends ControllerBase<CustoOperacional, CustoOperacionalDTOSaida, CustoOperacionalDTOEntrada>
        implements CustoOperacionalControllerDoc {

    @Autowired
    public CustoOperacionalController(CustoOperacionalService custoOperacionalService) {
        super(custoOperacionalService, CustoOperacional.class, CustoOperacionalDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<CustoOperacionalDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) CustoOperacionalDTOEntrada dto) {
        return super.adicionar(dto);
    }

    @GetMapping
    public ResponseEntity<List<CustoOperacionalDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<CustoOperacionalDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<CustoOperacionalDTOSaida> atualizar(@PathVariable Long id, @RequestBody CustoOperacionalDTOEntrada dto) {
        return super.atualizar(id, dto);
    }

    @Transactional
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> remover(@PathVariable Long id) {
        getServicoBase().remover(id);
        return ResponseEntity.noContent().build();
    }
}
