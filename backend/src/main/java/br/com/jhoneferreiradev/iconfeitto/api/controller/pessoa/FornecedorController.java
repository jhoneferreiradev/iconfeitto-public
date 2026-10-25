package br.com.jhoneferreiradev.iconfeitto.api.controller.pessoa;

import br.com.jhoneferreiradev.iconfeitto.api.controller.ControllerBase;
import br.com.jhoneferreiradev.iconfeitto.api.documentacao.pessoa.FornecedorControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.grupovalidacao.ValidacaoInclusao;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.pessoa.FornecedorDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.pessoa.FornecedorDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.pessoa.fornecedor.Fornecedor;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.pessoa.FornecedorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/fornecedores")
public class FornecedorController
        extends ControllerBase<Fornecedor, FornecedorDTOSaida, FornecedorDTOEntrada>
        implements FornecedorControllerDoc {

    @Autowired
    public FornecedorController(FornecedorService fornecedorService) {
        super(fornecedorService, Fornecedor.class, FornecedorDTOSaida.class);
    }

    @Transactional
    @PostMapping
    public ResponseEntity<FornecedorDTOSaida> adicionar(@RequestBody @Validated(ValidacaoInclusao.class) FornecedorDTOEntrada dto) {
        return super.adicionar(dto);
    }

    @GetMapping
    public ResponseEntity<List<FornecedorDTOSaida>> listar() {
        return super.listar();
    }

    @GetMapping("/{id}")
    public ResponseEntity<FornecedorDTOSaida> buscarPorId(@PathVariable Long id) {
        return super.buscarPorId(id);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<FornecedorDTOSaida> atualizar(@PathVariable Long id, @RequestBody FornecedorDTOEntrada dto) {
        return super.atualizar(id, dto);
    }

}
