# LumaDock

LumaDock é uma dock flutuante de vidro translúcido para o shell do Omarchy. Ela agrupa janelas por aplicativo, destaca o aplicativo em foco e mantém os atalhos fixados disponíveis quando os aplicativos estão fechados.

## Requisitos

- Omarchy com Hyprland, Quickshell e suporte a plugins do shell. Testado no Omarchy 4.5.0.
- As miniaturas usam a captura de janelas do Hyprland. Quando uma imagem está indisponível, a prévia exibe o ícone e o título da janela.

## Instalação

Para instalar a partir de uma cópia local deste repositório, execute na raiz do projeto. O diretório de destino deve estar livre para o clone.

```bash
plugins_dir="$HOME/.config/omarchy/plugins"
mkdir -p "$plugins_dir"
git clone -- "$(pwd -P)" "$plugins_dir/jean.lumadock"
omarchy plugin validate "$plugins_dir/jean.lumadock"
omarchy-shell shell rescanPlugins
omarchy plugin enable jean.lumadock
```

### Desfoque do fundo

Para aplicar o desfoque à superfície da dock, adicione esta regra a `~/.config/hypr/looknfeel.lua`. O efeito usa o desfoque do Hyprland quando ele está habilitado na sessão.

```lua
hl.layer_rule({
  match = { namespace = "^lumadock$" },
  blur = true,
  ignore_alpha = 0.08,
})
```

```bash
hyprctl reload
hyprctl configerrors
```

## Uso

- Clique no ícone de um aplicativo para abrir seu atalho ou focar uma janela que já está aberta.
- Passe o cursor sobre um ícone com janelas abertas para ver uma miniatura por janela. Clique na miniatura para focá-la ou no **×** no canto superior direito para fechar aquela janela.
- Abra a engrenagem para buscar aplicativos instalados, fixar atalhos e reordená-los com as setas. Também é possível abrir as configurações com `omarchy-shell jean.lumadock settings`.

| Configuração | Comportamento |
| --- | --- |
| Aplicativos abertos | Exibe todos os workspaces por padrão. Você pode limitar a exibição ao workspace atual. |
| Fixa | Reserva espaço na borda da tela. É o modo padrão. |
| Ocultar automaticamente | Revela a dock quando o cursor toca a borda escolhida. Em workspaces vazios, a dock permanece visível. A animação respeita a preferência de movimento do Omarchy. |
| Posição | Borda superior, inferior, esquerda ou direita. A borda inferior é o padrão. |

As preferências ficam em `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/lumadock.ini`. No primeiro uso, a LumaDock importa a ordem dos atalhos da dock nativa, quando ela está configurada. Se a dock nativa estiver habilitada, também poderá aparecer nos workspaces flutuantes.

Para desativar a LumaDock, execute `omarchy plugin disable jean.lumadock`.

## Desenvolvimento

- [LumaDock.qml](LumaDock.qml) acompanha as janelas, carrega as preferências e aciona os aplicativos.
- [DockSurface.qml](DockSurface.qml), [DockPreview.qml](DockPreview.qml) e [DockSettings.qml](DockSettings.qml) implementam a dock, as miniaturas e as configurações.
- [DockModel.js](DockModel.js) agrupa janelas, aplica o filtro por workspace e organiza os atalhos.
- [i18n/](i18n/) contém as traduções em português do Brasil e inglês.

Execute a validação do manifesto e os testes QML na raiz do projeto.

```bash
omarchy plugin validate .
env -u QT_QPA_PLATFORMTHEME QT_QPA_PLATFORM=offscreen \
  /usr/lib/qt6/bin/qmltestrunner -input tests
```
