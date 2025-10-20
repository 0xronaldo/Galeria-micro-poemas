module galeria_micro_poemas::galeria_micro_poemas {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self as balance, Balance};
    use sui::sui::SUI;
    use sui::event;

    const ETextoMuyLargo: u64 = 1;
    const EPagoInsuficiente: u64 = 2;
    const ENoEsAutor: u64 = 3;
    const MAX_CARACTERES: u64 = 280;
    const PRECIO_PUBLICACION: u64 = 100_000_000;

    public struct MicroPoema has key, store {
        id: UID,
        autor: address,
        contenido: vector<u8>,
        likes: u64,
        timestamp: u64,
    }
    public struct Galeria has key {
        id: UID,
        fondos: Balance<SUI>,
        total_poemas: u64,
    }
    

    public struct PoemaPublicado has copy, drop {
        poema_id: ID,
        autor: address,
    }

    public struct LikeDado has copy, drop {
        poema_id: ID,
        nuevo_total: u64,
    }
    fun init(ctx: &mut TxContext) {
        let galeria = Galeria {
            id: object::new(ctx),
            fondos: balance::zero<SUI>(),
            total_poemas: 0,
        };
        transfer::share_object(galeria);
    }
    

    #[allow(lint(self_transfer))]
    public fun publicar_poema(
        galeria: &mut Galeria,
        pago: Coin<SUI>,
        contenido: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(contenido.length() <= MAX_CARACTERES, ETextoMuyLargo);
        assert!(pago.value() >= PRECIO_PUBLICACION, EPagoInsuficiente);
        let pago_balance = coin::into_balance(pago);
        balance::join(&mut galeria.fondos, pago_balance);
        galeria.total_poemas = galeria.total_poemas + 1;
        let poema = MicroPoema {
            id: object::new(ctx),
            autor: ctx.sender(),
            contenido,
            likes: 0,
            timestamp: ctx.epoch(),
        };
        let poema_id = object::id(&poema);
        event::emit(PoemaPublicado { poema_id, autor: ctx.sender() });
        transfer::transfer(poema, ctx.sender());
    }

    public fun dar_like(poema: &mut MicroPoema) {
        poema.likes = poema.likes + 1;
        event::emit(LikeDado { poema_id: object::id(poema), nuevo_total: poema.likes });
    
    }


    #[allow(lint(share_owned))]
    public fun compartir_poema(poema: MicroPoema) {
        transfer::public_share_object(poema);
    }

    public fun eliminar_poema(poema: MicroPoema, ctx: &TxContext) {
        assert!(poema.autor == ctx.sender(), ENoEsAutor);
        let MicroPoema { id, autor: _, contenido: _, likes: _, timestamp: _ } = poema;
        object::delete(id);
    }

    public fun ver_contenido(poema: &MicroPoema): vector<u8> {
        poema.contenido
    }

    public fun ver_stats(poema: &MicroPoema): (address, u64, u64) {
        (poema.autor, poema.likes, poema.timestamp)
    }

    public fun ver_fondos_galeria(galeria: &Galeria): u64 {
        galeria.fondos.value()
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
