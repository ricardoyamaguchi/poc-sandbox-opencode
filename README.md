# PocSandbox

Aplicativo iOS de exemplo em SwiftUI com login via conta Google, dependências gerenciadas pelo CocoaPods e projeto Xcode gerado pelo [XcodeGen](https://github.com/yonaskolb/XcodeGen).

## Sumário

- [Sobre](#sobre)
- [Funcionalidades](#funcionalidades)
- [Requisitos](#requisitos)
- [Começando](#começando)
- [Comandos](#comandos)
- [Configuração do Google Sign-In](#configuração-do-google-sign-in)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Arquitetura](#arquitetura)
- [Solução de problemas](#solução-de-problemas)
- [Dependências](#dependências)

## Sobre

O PocSandbox demonstra um fluxo completo de autenticação com o Google em SwiftUI:

1. O app inicia verificando se há uma sessão salva.
2. Sem sessão, exibe a tela de login com o botão **Continuar com Google**.
3. Após a autenticação, exibe a tela inicial com avatar, nome, e-mail e opção de sair.

O projeto serve como base para experimentos (`sandbox`) e não possui testes, CI ou lint configurados.

## Funcionalidades

- Login com conta Google via SDK oficial (`GoogleSignIn`).
- Restauração automática da sessão anterior.
- Tratamento de cancelamento e de erros de autenticação.
- Tela inicial com dados do perfil e logout.
- Sessão gerenciada por `AuthViewModel` (`ObservableObject` + `async/await`).

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

O projeto inclui um **Client ID placeholder**; sem substituí-lo, o login não funciona e o app exibe um alerta explicando a configuração.

1. No [Google Cloud Console](https://console.cloud.google.com/), crie um **OAuth client ID** do tipo **iOS**.
2. Informe o bundle ID do app: `com.example.PocSandbox` (definido em `project.yml`).
3. Copie o Client ID gerado (formato `000000000000-xxxxxxxx.apps.googleusercontent.com`).
4. Edite o bloco `info` em [`project.yml`](project.yml) substituindo o placeholder:

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
│   ├── PocSandboxApp.swift   # Entry point e callback do OAuth
│   ├── ContentView.swift     # Roteamento entre login e home
│   ├── LoginView.swift       # Tela de login com Google
│   ├── HomeView.swift        # Tela inicial autenticada
│   ├── AuthViewModel.swift   # Estado e fluxo de autenticação
│   ├── Info.plist            # Gerado pelo XcodeGen a partir de project.yml
│   └── Assets.xcassets/
├── PocSandbox.xcodeproj      # Gerado — não editar
└── PocSandbox.xcworkspace    # Gerado pelo CocoaPods — abrir este
```

## Arquitetura

- **`AuthViewModel`** — classe `@MainActor` que configura o `GIDSignIn`, restaura a sessão, executa login/logout e expõe o estado para as views.
- **`ContentView`** — observa o estado de autenticação e decide entre `ProgressView`, `LoginView` e `HomeView`.
- **`LoginView`** — tela inicial com o botão de login e apresentação de erros.
- **`HomeView`** — perfil do usuário autenticado e ação de logout.
- **`PocSandboxApp`** — recebe a URL de callback do OAuth via `onOpenURL` e repassa ao `GIDSignIn`.

Fluxo resumido:

```text
App -> ContentView -> AuthViewModel.restorePreviousSignIn()
                          ├── sessão válida -> HomeView
                          └── sem sessão   -> LoginView -> Google -> HomeView
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
O `GIDClientID` ainda é o placeholder. Siga a seção [Configuração do Google Sign-In](#configuração-do-google-sign-in) e rode `make generate`.

**Avisos de dependências depreciadas**
`GoogleSignIn` (e suas dependências transitivas) está marcado como depreciado no CocoaPods. O pod continua funcional; para novos projetos, considere instalar o SDK via Swift Package Manager.

**Alterei fontes e o Xcode não viu**
Arquivos `.swift` em `PocSandbox/` são incluídos automaticamente, mas mudanças em `project.yml`, `Podfile` ou a criação de novas pastas exigem:

```bash
make generate
```

## Dependências

| Dependência | Versão | Uso |
| --- | --- | --- |
| [Alamofire](https://github.com/Alamofire/Alamofire) | ~> 5.10 | Cliente HTTP |
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) | ~> 10.1 | Autenticação Google |

As versões ficam fixadas no [`Podfile`](Podfile) e resolvidas em `Podfile.lock` (versionado).
