package br.com.jhoneferreiradev.iconfeitto.api.controller.empresa;

import br.com.jhoneferreiradev.iconfeitto.api.documentacao.empresa.ConfeitariaControllerDoc;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.conversordeobjeto.ConversorObjetos;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria.ConfeitariaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.entrada.empresa.confeitaria.NovaConfeitariaDTOEntrada;
import br.com.jhoneferreiradev.iconfeitto.api.modelo.saida.empresa.confeitaria.ConfeitariaDTOSaida;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.confeitaria.ConfeitariaService;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.empresa.usuario.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/confeitarias")
public class ConfeitariaController implements ConfeitariaControllerDoc {

    @Autowired
    private ConfeitariaService confeitariaService;

    @Autowired
    private UsuarioService usuarioService;

    @Transactional
    @PostMapping
    public ResponseEntity<ConfeitariaDTOSaida> adicionar(@RequestBody NovaConfeitariaDTOEntrada novaConfeitariaDTOEntrada) {
        Confeitaria confeitaria = ConversorObjetos.converter(novaConfeitariaDTOEntrada, NovaConfeitariaDTOEntrada.class, Confeitaria.class);
        confeitaria = confeitariaService.salvar(confeitaria);

        usuarioService.adicionarPrimeiroUsuarioDaConfeitaria(novaConfeitariaDTOEntrada, confeitaria);

        ConfeitariaDTOSaida saida = ConversorObjetos.converter(confeitaria, Confeitaria.class, ConfeitariaDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ConfeitariaDTOSaida> buscarPorId(@PathVariable Long id) {
        Confeitaria confeitaria = confeitariaService.getPorId(id);
        ConfeitariaDTOSaida saida = ConversorObjetos.converter(confeitaria, Confeitaria.class, ConfeitariaDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

    @Transactional
    @PatchMapping("/{id}")
    public ResponseEntity<ConfeitariaDTOSaida> atualizar(@PathVariable Long id, @RequestBody ConfeitariaDTOEntrada confeitariaDTOEntrada) {
        Confeitaria confeitariaExistente = confeitariaService.getPorId(id);

        ConversorObjetos.atualizarIgnorandoNulos(confeitariaDTOEntrada, confeitariaExistente);

        Confeitaria confeitariaAtualizada = confeitariaService.salvar(confeitariaExistente);
        ConfeitariaDTOSaida saida = ConversorObjetos.converter(confeitariaAtualizada, Confeitaria.class, ConfeitariaDTOSaida.class);
        return ResponseEntity.ok(saida);
    }

}
