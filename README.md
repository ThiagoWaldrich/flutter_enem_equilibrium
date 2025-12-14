# 📚 Equilirium - Banco de Questões Inteligente

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.22-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Supabase-PostgreSQL-green?logo=supabase" alt="Supabase">
  <img src="https://img.shields.io/badge/Status-Produção-brightgreen" alt="Status">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blueviolet" alt="Plataformas">
</div>

Um aplicativo completo desenvolvido em Flutter para organizar, filtrar e estudar questões de forma eficiente. Ideal para estudantes, professores e concurseiros.

## 🎥 Demonstração

<div align="center">
  <table>
    <tr>
      <td align="center"><strong>Banco de Questões</strong></td>
      <td align="center"><strong>Cadastro Inteligente</strong></td>
      <td align="center"><strong>Filtros Avançados</strong></td>
    </tr>
    <tr>
      <td><img src="https://via.placeholder.com/300x600/4CAF50/FFFFFF?text=Visualização+Grid/Lista" width="200"></td>
      <td><img src="https://via.placeholder.com/300x600/2196F3/FFFFFF?text=Formulário+Automático" width="200"></td>
      <td><img src="https://via.placeholder.com/300x600/9C27B0/FFFFFF?text=Filtros+Combinação" width="200"></td>
    </tr>
  </table>
</div>

## ✨ Funcionalidades Principais

### 🎯 **Cadastro Inteligente**
- ✅ Formulário que **limpa automaticamente** após salvar
- ✅ Upload de imagens direto da galeria
- ✅ Validação em tempo real
- ✅ Classificação por matéria, tópico e dificuldade

### 🔍 **Sistema de Estudos Otimizado**
- ✅ **Respostas ocultas** - Só aparecem quando você decide
- ✅ Filtros combinados (matéria + tópico + fonte + ano)
- ✅ Busca textual em todas as propriedades
- ✅ Ordenação por data, matéria ou dificuldade

### 📊 **Visualização Flexível**
- ✅ Modo Grid ou Lista (alternância com um clique)
- ✅ Cores automáticas por disciplina
- ✅ Cards informativos completos
- ✅ Diálogos de detalhes com zoom de imagens

### 🔒 **Backend Seguro**
- ✅ Autenticação por email (Supabase Auth)
- ✅ Banco de dados PostgreSQL
- ✅ Armazenamento de imagens no Supabase Storage
- ✅ Row Level Security para proteção de dados

## 🚀 Começando

### Pré-requisitos
1. **Flutter** 3.22 ou superior
2. **Conta no Supabase** (gratuita)
3. **Android Studio / Xcode** (para emuladores)

### Instalação Passo a Passo

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/questify.git
cd questify

# 2. Instale as dependências
flutter pub get

# 3. Configure as variáveis de ambiente
# Crie um arquivo .env na raiz com:
cp .env.example .env
# Edite .env com suas credenciais do Supabase

# 4. Execute o aplicativo
flutter run
