package br.com.jhoneferreiradev.iconfeitto.infra.servico.base;

import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadeBase;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.EntidadeComConfeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.entidade.empresa.confeitaria.Confeitaria;
import br.com.jhoneferreiradev.iconfeitto.dominio.excecao.IConfeittoException;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.ConfeitariaConectadaService;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseAtivavelRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.RepositorioBaseComConfeitariaRepository;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.validation.core.ValidavelAoSalvar;
import br.com.jhoneferreiradev.iconfeitto.dominio.repositorio.base.validation.core.ValidadorDeSalvamentoService;
import br.com.jhoneferreiradev.iconfeitto.dominio.servico.base.ServicoBase;
import lombok.Getter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

import static java.util.Objects.isNull;

public abstract class BaseServiceImpl<T> implements ServicoBase<T> {

    @Getter
    protected final JpaRepository<T, Long> repository;

    @Autowired
    private ValidadorDeSalvamentoService validadorDeSalvamentoService;

    @Autowired
    private ConfeitariaConectadaService confeitariaConectadaService;

    @Getter
    private final String nomeObjeto;

    protected BaseServiceImpl(JpaRepository<T, Long> repository,
                              String nomeObjeto) {
        this.repository = repository;
        this.nomeObjeto = nomeObjeto;
    }

    @Transactional
    @Override
    public T salvar(T objeto) {

        boolean precisaInformarConfeitaria = objeto instanceof EntidadeBase &&
                ((EntidadeBase) objeto).naoSalvo() &&
                objeto instanceof EntidadeComConfeitaria &&
                isNull(((EntidadeComConfeitaria) objeto).getConfeitaria());

        if (precisaInformarConfeitaria) {
            Confeitaria confeitaria = getConfeitariaConectada()
                    .orElseThrow(() -> new IConfeittoException("Confeitaria não encontrada para adicionar objeto", HttpStatus.INTERNAL_SERVER_ERROR));
            ((EntidadeComConfeitaria) objeto).setConfeitaria(confeitaria);
        }

        if (objeto instanceof ValidavelAoSalvar) {
            validadorDeSalvamentoService.valid((ValidavelAoSalvar) objeto);
        }

        objeto = repository.save(objeto);
        return objeto;
    }

    protected Optional<Confeitaria> getConfeitariaConectada() {
        return confeitariaConectadaService.getConfeitariaConectada();
    }

    @Override
    public Optional<T> buscarPorId(Long id) {
        return repository.findById(id);
    }

    @Override
    public List<T> listarTodos() {
        if (repository instanceof RepositorioBaseComConfeitariaRepository) {
            Confeitaria confeitariaConectada = getConfeitariaConectada()
                    .orElseThrow(() -> new IConfeittoException("Confeitaria não encontrada para adicionar objeto", HttpStatus.INTERNAL_SERVER_ERROR));
            return ((RepositorioBaseComConfeitariaRepository) repository).findAllByConfeitaria(confeitariaConectada);
        }

        return repository.findAll();
    }

    @Override
    public List<T> listarTodosAtivos() {
        if (repository instanceof RepositorioBaseAtivavelRepository<?,?>) {
            Confeitaria confeitariaConectada = getConfeitariaConectada()
                    .orElseThrow(() -> new IConfeittoException("Confeitaria não encontrada para adicionar objeto", HttpStatus.INTERNAL_SERVER_ERROR));
            return ((RepositorioBaseAtivavelRepository) repository).findAllByAtivoTrueAndConfeitaria(confeitariaConectada);
        }

        return listarTodos();
    }

    @Transactional
    @Override
    public void remover(Long id) {
        repository.deleteById(id);
    }

}