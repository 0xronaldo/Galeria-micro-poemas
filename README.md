# Galería de Micro Poemas (Sui)

Es un contrato para una galería on-chain de micro poemas. Los usuarios pagan una tarifa para publicar un micro poema (hasta 280 bytes), reciben el objeto del poema como propietario, otros pueden dar like y el contrato acumula los fondos en una galería compartida.

## Módulo

- Paquete: `galeria_micro_poemas`
- Módulo: `galeria_micro_poemas::galeria_micro_poemas`

## Concepto

 Cada micro poema es un objeto con autor, contenido, contador de likes y marca de tiempo. es posible  Publicar cuesta `PRECIO_PUBLICACION = 100_000_000` MIST (0.1 SUI), límite de `MAX_CARACTERES = 280` bytes.
 Al publicar se emite un evento y la galería acumula los fondos, Cualquiera puede dar like a un poema; solo el autor puede eliminarlo.

## Estructuras y eventos

- `struct Galeria has key` (objeto compartido): fondos `Balance<SUI>`, `total_poemas`.
- `struct MicroPoema has key, store`: `autor`, `contenido: vector<u8>`, `likes`, `timestamp`.
- Eventos: `PoemaPublicado { poema_id, autor }`, `LikeDado { poema_id, nuevo_total }`.

## Funciones públicas

- `init(ctx)`: crea y comparte la `Galeria`. Se ejecuta al publicar el paquete.
- `publicar_poema(&mut Galeria, pago: Coin<SUI>, contenido: vector<u8>, ctx)`: valida longitud y pago, acumula fondos, crea el `MicroPoema`, emite evento y transfiere el poema al autor.
- `dar_like(&mut MicroPoema)`: incrementa `likes` y emite evento.
- `compartir_poema(poema: MicroPoema)`: comparte públicamente el objeto poema.
- `eliminar_poema(poema: MicroPoema, ctx)`: solo el autor puede eliminar su poema.
- Lectura:
  - `ver_contenido(&MicroPoema): vector<u8>`
  - `ver_stats(&MicroPoema): (address, u64, u64)` (autor, likes, timestamp)
  - `ver_fondos_galeria(&Galeria): u64` (en MIST)

Códigos de error: `1` (texto muy largo), `2` (pago insuficiente), `3` (no es autor).

## Uso

Requisitos: tener `sui` instalado y una cuenta configurada.

1) Compilar y probar

```zsh
sui move build
sui move test
```

2) Publicar el paquete (ejecuta `init` y crea el objeto `Galeria` compartido)

```zsh
sui client publish --gas-budget 100000000
```

- Anota el `PackageID` y el `ObjectID` de `Galeria` del resultado de la transacción.

3) Publicar un micro poema

```zsh
# Preparar el pago (ejemplo: 0.1 SUI = 100_000_000 MIST)
# Usa una moneda SUI con al menos ese saldo: <COIN_ID>
# Contenido como bytes hex de UTF-8 (vector<u8>), p.ej. "Hola" -> 0x486f6c61

sui client call \
  --package <PACKAGE_ID> \
  --module galeria_micro_poemas \
  --function publicar_poema \
  --args <GALERIA_OBJECT_ID> <COIN_ID> 0x486f6c61...
```

4) Dar like a un poema

```zsh
# Pasa el ObjectID del poema, será tomado como &mut MicroPoema
sui client call \
  --package <PACKAGE_ID> \
  --module galeria_micro_poemas \
  --function dar_like \
  --args <POEMA_OBJECT_ID> 
```

5) Eliminar un poema (solo autor)

```zsh
sui client call \
  --package <PACKAGE_ID> \
  --module galeria_micro_poemas \
  --function eliminar_poema \
  --args <POEMA_OBJECT_ID>
```

6) Consultas

- Contenido: usa `ver_contenido(&MicroPoema)` vía `dev-inspect` o lecturas RPC.
- Estadísticas: `ver_stats(&MicroPoema)` devuelve `(autor, likes, timestamp)`.
- Fondos de la galería: `ver_fondos_galeria(&Galeria)` en MIST.

Notas:
- El argumento `contenido` debe ser `vector<u8>`; utiliza bytes hex de texto UTF-8 para llamadas desde CLI.
- No hay función de retiro de fondos; los SUI quedan acumulados en `Galeria`.
- `timestamp` usa `ctx.epoch()`.

## Tests

Los tests de ejemplo están en `sources/galeria_tests.move`.

```zsh
sui move test
```
