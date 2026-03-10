// Configurações
const CONFIG = {
    WHATSAPP_NUMBER: '5511999999999', // Substitua pelo seu número
    BUSINESS_NAME: 'Nails Designer',
    WORKING_HOURS: {
        start: 9, // 9:00
        end: 19,  // 19:00
        interval: 60 // minutos entre horários
    }
};

// Estado da aplicação
let agendamentos = [];

// Inicialização
document.addEventListener('DOMContentLoaded', function() {
    setTimeout(() => {
        document.getElementById('splash-screen').style.display = 'none';
        document.getElementById('main-content').style.display = 'block';
    }, 2000);

    // Configurar data mínima (hoje)
    const hoje = new Date().toISOString().split('T')[0];
    document.getElementById('data').min = hoje;
    document.getElementById('data').value = hoje;

    // Carregar agendamentos salvos
    carregarAgendamentos();

    // Configurar menu
    document.getElementById('menu-toggle').addEventListener('click', toggleMenu);

    // Fechar menu ao clicar fora
    document.addEventListener('click', function(event) {
        const sidebar = document.getElementById('sidebar');
        const menuBtn = document.getElementById('menu-toggle');
        
        if (!sidebar.contains(event.target) && !menuBtn.contains(event.target) && sidebar.classList.contains('active')) {
            sidebar.classList.remove('active');
        }
    });

    // Atualizar horários quando mudar a data
    document.getElementById('data').addEventListener('change', function() {
        atualizarHorariosDisponiveis(this.value);
    });

    // Carregar horários iniciais
    atualizarHorariosDisponiveis(hoje);
});

// Funções de Navegação
function toggleMenu() {
    document.getElementById('sidebar').classList.toggle('active');
}

function showSection(sectionId) {
    // Esconder todas as seções
    document.querySelectorAll('.section').forEach(section => {
        section.classList.remove('active');
    });
    
    // Mostrar seção selecionada
    document.getElementById(sectionId).classList.add('active');
    
    // Fechar menu
    document.getElementById('sidebar').classList.remove('active');
    
    // Atualizar lista de agendamentos se necessário
    if (sectionId === 'meus-agendamentos') {
        exibirAgendamentos();
    }
}

// Funções de Agendamento
function atualizarHorariosDisponiveis(data) {
    const selectHorarios = document.getElementById('hora');
    selectHorarios.innerHTML = '<option value="">Selecione um horário</option>';
    
    const horariosOcupados = agendamentos
        .filter(ag => ag.data === data)
        .map(ag => ag.hora);
    
    for (let hora = CONFIG.WORKING_HOURS.start; hora < CONFIG.WORKING_HOURS.end; hora++) {
        for (let min = 0; min < 60; min += CONFIG.WORKING_HOURS.interval) {
            const horaFormatada = `${hora.toString().padStart(2, '0')}:${min.toString().padStart(2, '0')}`;
            
            if (!horariosOcupados.includes(horaFormatada)) {
                const option = document.createElement('option');
                option.value = horaFormatada;
                option.textContent = horaFormatada;
                selectHorarios.appendChild(option);
            }
        }
    }
}

function agendar() {
    // Validar campos
    const nome = document.getElementById('nome').value;
    const telefone = document.getElementById('telefone').value;
    const servico = document.getElementById('servico').value;
    const data = document.getElementById('data').value;
    const hora = document.getElementById('hora').value;
    const observacoes = document.getElementById('observacoes').value;

    if (!nome || !telefone || !servico || !data || !hora) {
        alert('Por favor, preencha todos os campos obrigatórios!');
        return;
    }

    // Validar telefone (mínimo 10 dígitos)
    const telefoneLimpo = telefone.replace(/\D/g, '');
    if (telefoneLimpo.length < 10 || telefoneLimpo.length > 11) {
        alert('Por favor, digite um número de WhatsApp válido!');
        return;
    }

    // Nome do serviço selecionado
    const selectServico = document.getElementById('servico');
    const nomeServico = selectServico.options[selectServico.selectedIndex].text;

    // Criar objeto do agendamento
    const agendamento = {
        id: Date.now(),
        nome,
        telefone: telefoneLimpo,
        servico,
        nomeServico,
        data,
        hora,
        observacoes,
        dataAgendamento: new Date().toISOString()
    };

    // Salvar agendamento
    agendamentos.push(agendamento);
    salvarAgendamentos();

    // Preparar mensagem para WhatsApp
    const mensagem = prepararMensagemWhatsApp(agendamento);
    
    // Enviar para WhatsApp
    const urlWhatsApp = `https://api.whatsapp.com/send?phone=${CONFIG.WHATSAPP_NUMBER}&text=${encodeURIComponent(mensagem)}`;
    
    // Abrir WhatsApp
    window.open(urlWhatsApp, '_blank');

    // Limpar formulário
    document.getElementById('nome').value = '';
    document.getElementById('telefone').value = '';
    document.getElementById('observacoes').value = '';
    
    // Atualizar horários disponíveis
    atualizarHorariosDisponiveis(data);
    
    // Mostrar mensagem de sucesso
    alert('Agendamento realizado com sucesso! Verifique seu WhatsApp para confirmação.');
    
    // Ir para meus agendamentos
    showSection('meus-agendamentos');
}

function prepararMensagemWhatsApp(agendamento) {
    return `🔔 *NOVO AGENDAMENTO - ${CONFIG.BUSINESS_NAME}* 🔔

👤 *Cliente:* ${agendamento.nome}
📱 *WhatsApp:* ${agendamento.telefone}
💅 *Serviço:* ${agendamento.nomeServico}
📅 *Data:* ${formatarData(agendamento.data)}
⏰ *Horário:* ${agendamento.hora}
${agendamento.observacoes ? `📝 *Observações:* ${agendamento.observacoes}` : ''}

✅ *Status:* Aguardando confirmação

--- 
Mensagem automática do seu aplicativo Nails Designer`;
}

function formatarData(dataISO) {
    const [ano, mes, dia] = dataISO.split('-');
    return `${dia}/${mes}/${ano}`;
}

// Funções de Persistência
function salvarAgendamentos() {
    localStorage.setItem('nails_agendamentos', JSON.stringify(agendamentos));
}

function carregarAgendamentos() {
    const salvos = localStorage.getItem('nails_agendamentos');
    if (salvos) {
        agendamentos = JSON.parse(salvos);
    }
}

function exibirAgendamentos() {
    const lista = document.getElementById('lista-agendamentos');
    
    if (agendamentos.length === 0) {
        lista.innerHTML = '<p class="text-center">Nenhum agendamento encontrado.</p>';
        return;
    }

    // Ordenar por data e hora
    const agendamentosOrdenados = [...agendamentos].sort((a, b) => {
        if (a.data !== b.data) {
            return a.data.localeCompare(b.data);
        }
        return a.hora.localeCompare(b.hora);
    });

    lista.innerHTML = agendamentosOrdenados.map(ag => `
        <div class="agendamento-item">
            <div class="data">${formatarData(ag.data)} às ${ag.hora}</div>
            <div class="servico">${ag.nomeServico}</div>
            <div><strong>Cliente:</strong> ${ag.nome}</div>
            <div><small>Agendado em: ${new Date(ag.dataAgendamento).toLocaleDateString()}</small></div>
        </div>
    `).join('');
}

// Instalação do PWA
if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
        navigator.serviceWorker.register('service-worker.js')
            .then(function(registration) {
                console.log('ServiceWorker registrado com sucesso:', registration.scope);
            })
            .catch(function(error) {
                console.log('Falha ao registrar ServiceWorker:', error);
            });
    });
}
