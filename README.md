## Post Vitam

Um pet game com estética retrô e inspiração gótica. Cuide do seu Penitente gerenciando quatro status principais — Fé, Entretenimento, Fervor e Vitalidade — compre consumíveis e skins, jogue um minigame para ganhar moedas e receba lembretes quando o seu cuidado for necessário.

### Funcionalidades
- **Status do Pet**: Fé, Entretenimento, Fervor e Vitalidade com degradação automática ao longo do tempo.
- **Lojas temáticas**:
  - Santas Chagas (Fé)
  - Beijos Fervorosos (Fervor)
  - Alambique Sagrado (Vitalidade)
  - Nundinae (Skins)
- **Inventário**: gerencie consumíveis e skins, equipe/descarte itens e acompanhe quantidades.
- **Minigame Spelunca**: toque nas moedas que caem para pontuar e ganhar moedas (Flame Engine).
- **Notificações locais**: lembretes quando status estiverem baixos (quando o app está em segundo plano).
- **Persistência local**: `sqflite` (mobile) e `sqflite_common_ffi` (desktop) para salvar status e inventário.
- **UI Responsiva**: fontes e tema pixel art com elementos dourados.

---

Dependências principais:
- `flame`: motor 2D para o minigame
- `sqflite` e `sqflite_common_ffi`: banco local (mobile/desktop)
- `flutter_local_notifications`: notificações locais

---

## Como jogar
- Navegue entre as áreas deslizando lateralmente:
  - `Ecclesia` (Fé)
  - `Montes` (Fervor)
  - `Albero` (Vitalidade)
  - `Spelunca` (minigame)
- Use o botão de inventário para consumir itens e equipar skins.
- Entre nas lojas correspondentes para comprar consumíveis e skins usando moedas.
- No minigame (`Spelunca`), toque nas moedas que caem. Cada acerto rende pontos; sua recompensa final em moedas é `score * 30`.

Degradação de status:
- Quando o app está aberto, os status sofrem pequenas perdas periódicas.
- Ao retomar o app após um tempo, uma degradação proporcional é aplicada.

Notificações:
- O app solicita permissão ao iniciar.
- Lembretes são enviados se o app estiver em segundo plano e algum status crítico for detectado.

Reset de progresso (apenas para debug):
- No painel de configurações da tela principal, existe uma ação para zerar inventário e restaurar os status para o início.

---