# PocSandbox

Aplicativo iOS em SwiftUI para registrar compras feitas em mercados físicos, com login via conta Google, busca de mercados próximos por geolocalização, dependências gerenciadas pelo CocoaPods e projeto Xcode gerado pelo [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Sumário

- [Sobre](#sobre)
- [Funcionalidades](#funcionalidades)
- [Requisitos](#requisitos)
- [Começando](#começando)
- [Comandos](#comandos)
- [Configuração do Google Sign-In](#configuração-do-google-sign-in)
- [Busca de mercados com MapKit](#busca-de-mercados-com-mapkit)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Arquitetura](#arquitetura)
- [Solução de problemas](#solução-de-problemas)
- [Contribuição](#contribuição)
- [Dependências](#dependências)

## Sobre

O PocSandbox permite iniciar e acompanhar compras em mercados físicos:

1. O app inicia verificando se há uma sessão salva.
2. Sem sessão, exibe a tela de login com o botão **Continuar com Google**.
3. Após a autenticação, a tela inicial mostra, no topo, os carrinhos em aberto, pergunta **Onde você está comprando?** e lista os **Mercados perto de você**, com um campo para filtrar pelo nome parcial do mercado.
4. A lista de mercados é obtida pela localização do aparelho usando o **MapKit** (`MKLocalSearch`).
5. Ao tocar em um mercado, um carrinho é aberto e passa a aparecer no topo da tela. Os carrinhos ficam salvos localmente entre execuções.

O projeto serve como base para experimentos (`sandbox`) e não possui testes, CI ou lint configurados.

## Funcionalidades

- Login com conta Google via SDK oficial (`GoogleSignIn`).
- Restauração automática da sessão anterior.
- Tela inicial com carrinhos em aberto, pergunta de contexto e mercados próximos.
- Permissão de localização solicitada ao abrir a home; mensagem e atalho para Ajustes quando negada.
- Busca de mercados por geolocalização com o **MapKit** (`MKLocalSearch`), sem chave de API.
- Campo de busca que filtra os mercados próximos pelo nome parcial, ignorando maiúsculas e acentos.
- Carrinhos abertos com total e status, persistidos em `UserDefaults` (`CartStore`).
- Tema nativo adaptável ao modo claro/escuro do device, usando cores semânticas do sistema e `Color.accentColor` (asset `AccentColor`).
- Home com header verde, cards arredondados e card cinza para o aviso de localização.
- Logout pelo menu de conta no ícone de carrinho do header.
- Sessão gerenciada por `AuthService` (`ObservableObject` + `async/await`).

## Requisitos

| Ferramenta | Versão |
| --- | --- |
| macOS | Compatível com Xcode 26.3 |
| Xcode | 26.3 |
| iOS (deployment target) | 17.0 |
| Swift | 5.0 (linguagem) |
| XcodeGen | 2.35+ |
| CocoaPods | 1.15+ |

Instalação das ferramentas auxiliares:

```bash
brew install xcodegen cocoapods
```

> O SDK do Xcode 26.3 é o iOS 26.2, mas o app tem deployment target iOS 17.0.
> O simulador padrão dos scripts é `iPhone 17` (runtime iOS 26.3); use `SIMULATOR_NAME` para trocar.

## Começando

1. Clone o repositório:

   ```bash
   git clone <url-do-repositorio>
   cd poc-sandbox-opencode
   ```

2. Gere o projeto e instale as dependências:

   ```bash
   make generate
   ```

3. Abra o **workspace** no Xcode:

   ```bash
   make open
   ```

4. Compile e execute no simulador:

   ```bash
   make run
   ```

> Sempre abra/build o `PocSandbox.xcworkspace`, nunca o `PocSandbox.xcodeproj`.
> O `.xcodeproj` é gerado pelo XcodeGen a partir de `project.yml` e não deve ser editado manualmente.

## Comandos

Todos os comandos ficam disponíveis pelo `Makefile`:

```bash
make help
```

| Comando | Descrição |
| --- | --- |
| `make generate` | Gera o `.xcodeproj` e executa `pod install` |
| `make build` | Compila o workspace na configuração atual |
| `make debug` | Compila em `Debug` |
| `make release` | Compila em `Release` |
| `make run` | Compila, instala e executa no simulador |
| `make open` | Abre o workspace no Xcode |
| `make clean` | Remove o diretório de build local |
| `make distclean` | Remove build, Pods e arquivos gerados |

As variáveis podem ser sobrescritas na linha de comando:

```bash
make run SIMULATOR_NAME="iPhone 17 Pro" BUNDLE_ID=com.exemplo.App
make build CONFIGURATION=Release
```

Os alvos delegam para os scripts em [`scripts/`](scripts), que também podem ser executados diretamente:

- `scripts/generate.sh`
- `scripts/build.sh`
- `scripts/run.sh`

## Configuração do Google Sign-In

O login usa o **Client ID OAuth** definido como `GIDClientID` em [`project.yml`](project.yml) e o esquema de URL correspondente. Sem um Client ID válido do seu projeto, o login não funciona e o app exibe um alerta explicando a configuração.

1. No [Google Cloud Console](https://console.cloud.google.com/), crie um **OAuth client ID** do tipo **iOS**.
2. Informe o bundle ID do app: `com.example.PocSandbox` (definido em `project.yml`).
3. Copie o Client ID gerado (formato `000000000000-xxxxxxxx.apps.googleusercontent.com`).
4. Edite o bloco `info` em [`project.yml`](project.yml) com o Client ID do seu projeto:

   ```yaml
   GIDClientID: SEU_CLIENT_ID.apps.googleusercontent.com
   CFBundleURLTypes:
     - CFBundleTypeRole: Editor
       CFBundleURLSchemes:
         - com.googleusercontent.apps.SEU_CLIENT_ID
   ```

   O esquema de URL é o Client ID invertido: remova o sufixo `.apps.googleusercontent.com` e use o prefixo `com.googleusercontent.apps.`.

5. Regenera o projeto:

   ```bash
   make generate
   ```

6. Compile e teste o login:

   ```bash
   make run
   ```

## Busca de mercados com MapKit

A busca de mercados próximos usa o **`MKLocalSearch`** do MapKit, sem chave de API, faturamento ou configuração adicional. O app consulta o termo `supermercado` em um raio de 5 km ao redor da localização atual, descarta resultados fora do raio, remove duplicatas e ordena do mais próximo para o mais distante.

Na home, o campo **Digite o nome do mercado** filtra a lista já carregada pelo nome parcial, sem diferenciar maiúsculas nem acentos (`localizedStandardContains`). Com o campo vazio, todos os mercados próximos são exibidos.

- Requer conexão com a internet; a busca é feita nos servidores da Apple.
- Usa `MKMapItem.location`/`address` no iOS 26+ e `placemark` em versões anteriores.
- Não retorna nota nem quantidade de avaliações; o modelo `Market` não possui mais esses campos.
- Para ajustar o termo ou o raio, edite [`MapKitMarketService.swift`](PocSandbox/Core/MarketSearch/MapKitMarketService.swift).

> No simulador, defina uma localização em **Features › Location** (por exemplo, *Apple* ou uma coordenada no Brasil) para que a busca retorne mercados.

## Permissão de localização

A descrição de uso fica em `NSLocationWhenInUseUsageDescription`, definida em [`project.yml`](project.yml). O app solicita a permissão ao abrir a home. Se o acesso for negado, a lista de mercados é substituída pelo card cinza **Permita o acesso à localização para ver mercados próximos.**; tocar no card abre os Ajustes do sistema. Após a autorização, o app mantém a atualização de localização ativa até receber a primeira posição, ignora o erro transitório `kCLErrorDomain 0` (`locationUnknown`) e, após 10 segundos sem sucesso, mostra um card tocável para tentar novamente.

## Estrutura do projeto

```text
.
├── Makefile                  # Atalhos de geração, build e execução
├── project.yml               # Fonte do projeto Xcode (XcodeGen)
├── Podfile / Podfile.lock    # Dependências CocoaPods
├── scripts/
│   ├── generate.sh           # xcodegen generate + pod install
│   ├── build.sh              # xcodebuild do workspace
│   └── run.sh                # build + simulador + install + launch
├── PocSandbox/
│   ├── App/
│   │   ├── PocSandboxApp.swift      # Entry point e callback do OAuth
│   │   ├── AppRootView.swift        # Root view que renderiza a rota atual
│   │   └── AppCoordinator.swift     # Roteamento global loading/login/home
│   ├── Core/
│   │   ├── Auth/
│   │   │   └── AuthService.swift    # Sessão e fluxo de autenticação Google
│   │   ├── DesignSystem/
│   │   │   ├── Theme.swift          # Cores semânticas nativas (claro/escuro)
│   │   │   └── CardStyle.swift      # Modificadores de card do layout
│   │   ├── Location/
│   │   │   └── LocationProvider.swift # Permissão e localização (CoreLocation)
│   │   ├── Models/
│   │   │   ├── Cart.swift           # Modelo de carrinho e persistência local
│   │   │   └── Market.swift         # Modelo de mercado
│   │   └── MarketSearch/
│   │       └── MapKitMarketService.swift # Busca de mercados com MKLocalSearch
│   ├── Features/
│   │   ├── Login/
│   │   │   ├── LoginView.swift      # Tela de login com Google
│   │   │   ├── LoginViewModel.swift # Estado e ações do login
│   │   │   └── LoginCoordinator.swift # Fluxo de login
│   │   └── Home/
│   │       ├── HomeView.swift       # Carrinhos, pergunta e mercados próximos
│   │       ├── HomeViewModel.swift  # Estado, localização, mercados e carrinhos
│   │       └── HomeCoordinator.swift # Fluxo da home e abertura dos Ajustes
│   ├── Info.plist                   # Gerado pelo XcodeGen a partir de project.yml
│   └── Assets.xcassets/
├── PocSandbox.xcodeproj             # Gerado — não editar
└── PocSandbox.xcworkspace           # Gerado pelo CocoaPods — abrir este
```

## Arquitetura

Convenção do projeto: telas e features seguem **MVVM-C** — Views declarativas, ViewModels com estado e regras de negócio, e Coordinators responsáveis pela navegação. Ao alterar uma tela que ainda tenha lógica na view, mova essa lógica para um ViewModel/Coordinator.

- **`AuthService`** — classe `@MainActor` que configura o `GIDSignIn`, restaura a sessão, executa login/logout e publica o estado de autenticação.
- **`AppCoordinator`** — observa o `AuthService` e decide a rota global: carregando, login ou home.
- **`AppRootView`** — renderiza a rota atual do `AppCoordinator` e inicia a restauração da sessão.
- **`LoginCoordinator`** — cria o `LoginViewModel` e monta o fluxo de login.
- **`LoginViewModel`** — expõe estado de login/erro e delega a autenticação ao `AuthService`.
- **`LoginView`** — tela declarativa de login com o botão do Google.
- **`HomeCoordinator`** — cria o `HomeViewModel` e concentra navegação, como abrir os Ajustes do sistema.
- **`HomeViewModel`** — mantém carrinhos, permissão/localização, mercados, filtro por nome e logout; também formata datas, distâncias e moeda.
- **`HomeView`** — home declarativa com header, carrinhos, pergunta, campo de busca e mercados próximos.
- **`Theme` / `CardStyle`** — cores semânticas nativas (claro/escuro), `Color.accentColor` e cards do layout.
- **`LocationProvider`** — classe `@MainActor` que encapsula o `CLLocationManager`, publica o status de autorização e a localização atual.
- **`MapKitMarketService`** — busca supermercados próximos com `MKLocalSearch`, filtra pelo raio, remove duplicatas e converte os resultados em `Market`.
- **`CartStore`** — mantém os carrinhos em aberto e persiste em `UserDefaults`.
- **`PocSandboxApp`** — recebe a URL de callback do OAuth via `onOpenURL` e repassa ao `GIDSignIn`.

Fluxo resumido:

```text
PocSandboxApp -> AppRootView -> AppCoordinator.start()
                                  ├── restaurando sessão -> ProgressView
                                  ├── sem sessão -> LoginFlowView
                                  │     └── LoginCoordinator -> LoginViewModel -> AuthService
                                  └── sessão válida -> HomeFlowView
                                        └── HomeCoordinator -> HomeViewModel
                                              ├── LocationProvider -> MapKit -> mercados
                                              └── CartStore -> carrinhos
```

## Solução de problemas

**`xcodebuild` falha pedindo destino**
O build exige um destino explícito. Use os scripts/Makefile ou:

```bash
xcodebuild -workspace PocSandbox.xcworkspace -scheme PocSandbox \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**`iOS <versão> is not installed` ou "Supported platforms ... is empty"**
O componente de plataforma iOS está ausente:

```bash
xcodebuild -downloadPlatform iOS
```

**O botão de login exibe um alerta de configuração**
O `GIDClientID` não está configurado ou não corresponde ao OAuth client ID do projeto. Siga a seção [Configuração do Google Sign-In](#configuração-do-google-sign-in) e rode `make generate`.

**A home mostra "Permita o acesso à localização para ver mercados próximos."**
A permissão foi negada. Toque no card do aviso para abrir os Ajustes e habilite **Localização** para o PocSandbox, ou redefina a permissão em **Ajustes › Privacidade e Segurança › Localização**.

**A home mostra "Não foi possível obter sua localização." ou `kCLErrorDomain error 0`**
O erro 0 (`locationUnknown`) é transitório e agora é ignorado; o app tenta obter a localização por até 10 segundos. No simulador, defina uma localização em **Features › Location** ou via terminal:

```bash
xcrun simctl location "iPhone 17 Pro" set -23.561684,-46.655981
```

Depois toque no card de erro ou puxe a home para atualizar.

**Nenhum mercado encontrado por perto**
Confirme que o simulador ou aparelho tem uma localização definida (no simulador: **Features › Location**) e conexão com a internet. A busca usa o MapKit (`MKLocalSearch`) com o termo `supermercado` em um raio de 5 km; em áreas com poucos dados do Apple Maps, o resultado pode ser vazio. Se houver um termo no campo de busca, limpe-o para ver todos os mercados.

**Avisos de dependências depreciadas**
`GoogleSignIn` (e suas dependências transitivas) está marcado como depreciado no CocoaPods. O pod continua funcional; para novos projetos, considere instalar o SDK via Swift Package Manager.

**Alterei fontes e o Xcode não viu**
Arquivos `.swift` em `PocSandbox/` são incluídos automaticamente, mas mudanças em `project.yml`, `Podfile` ou a criação de novas pastas exigem:

```bash
make generate
```

## Contribuição

Antes de qualquer push, atualize este `README.md` para refletir a alteração: novas telas/fluxos, comandos, scripts, dependências, configuração ou comportamento. Não envie alterações sem a atualização correspondente da documentação.

## Dependências

| Dependência | Versão | Uso |
| --- | --- | --- |
| [Alamofire](https://github.com/Alamofire/Alamofire) | ~> 5.10 | Cliente HTTP |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | ~> 10.1 | Autenticação Google |

As versões ficam fixadas no [`Podfile`](Podfile) e resolvidas em `Podfile.lock` (versionado).

A localização usa `CoreLocation` e a busca de mercados usa `MapKit`, ambos frameworks nativos; não há pod adicional para esses recursos.
