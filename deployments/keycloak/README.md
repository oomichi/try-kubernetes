# Try Keycloak

## Keycloak organization

同一realm においてマルチテナントを実現するための機能。
同一realm とすることでOpenID における同一client-id、client-secretのセットでマルチテナントが実現できる。
通常、frontendやbackendではKeycloakやAuth0、Azure B2Cなどの認証システムの単一の同一client-id、client-secretのセットを指定することになっている。
既存の仕組みを使う上で単一セットを指定できることは重要である。
さもなければ、独自にrealmを切り替えるような機能を実装することになってしまう。

Keycloak organizationでは、同一realm配下に複数のorganizationsを作成し、そこにusersを所属させることでマルチテナントを実現する。
organizationに属するuserのaccess-tokenには下記のようにorganizationというkeyが追加され、そこにどのorganizationに属しているのかが示されるようになる。

```
{
  "exp": 1774745939,
  "iat": 1774745639,
  "jti": "onrtro:249307ca-386a-d246-2fb6-8965b9ce3fc8",
  "iss": "http://localhost:18080/realms/realm01",
  "aud": "account",
  "sub": "c9978835-2314-4687-a524-8f6897a0b33d",
  ..
  "organization": [
    "org01"
  ],
  ..
}
```

frontendやbackendはこの値を見て、テナント毎の情報を提供するように挙動を実装する。

現時点で理解したふるまいは次の通り。

- access-token取得時、scopeにopenidの代わりにorganizationを指定する必要がある。
- organization名は変更可能。それとは別にorganization aliasがあり、それは一意かつorganization作成時から変更不可となっている。
- access-tokenのorganizationにはorganization aliasが渡されるため、一意かつ変更不可が保たれている。これにより、access-tokenのorganizationに依存した実装をfrontend、backendで可能である。
- ドキュメント上domain名から自動的にorganizationを振り分けられるように見えるが、期待した動作をしていない。明示的なorganization所属処理が必要となっている。何らかの設定不足の可能性がある。

