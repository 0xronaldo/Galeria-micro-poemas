#[test_only]
module galeria_micro_poemas::galeria_tests {
    use sui::test_scenario as ts;
    use sui::coin;
    use sui::sui::SUI;
    use galeria_micro_poemas::galeria_micro_poemas::{Self, Galeria, MicroPoema};

    const ADMIN: address = @0xAD;
    const USER1: address = @0xA1;
    const USER2: address = @0xA2;

    #[test]
    fun test_publicar_poema() {
        let mut scenario = ts::begin(ADMIN);
        {
            galeria_micro_poemas::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, USER1);
        {
            let mut galeria = ts::take_shared<Galeria>(&scenario);
            let pago = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(&mut scenario));
            galeria_micro_poemas::publicar_poema(&mut galeria, pago, b"Versos del alma", ts::ctx(&mut scenario));
            ts::return_shared(galeria);
        };
        ts::next_tx(&mut scenario, USER1);
        {
            assert!(ts::has_most_recent_for_sender<MicroPoema>(&scenario), 0);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_dar_like() {
        let mut scenario = ts::begin(ADMIN);
        {
            galeria_micro_poemas::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, USER1);
        {
            let mut galeria = ts::take_shared<Galeria>(&scenario);
            let pago = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(&mut scenario));
            galeria_micro_poemas::publicar_poema(&mut galeria, pago, b"Mi poema", ts::ctx(&mut scenario));
            ts::return_shared(galeria);
        };
        ts::next_tx(&mut scenario, USER2);
        {
            let mut poema = ts::take_from_address<MicroPoema>(&scenario, USER1);
            galeria_micro_poemas::dar_like(&mut poema);
            let (_, likes, _) = galeria_micro_poemas::ver_stats(&poema);
            assert!(likes == 1, 0);
            ts::return_to_address(USER1, poema);
        };
        ts::end(scenario);
    }

    #[test]
    fun test_eliminar_poema() {
        let mut scenario = ts::begin(ADMIN);
        {
            galeria_micro_poemas::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, USER1);
        {
            let mut galeria = ts::take_shared<Galeria>(&scenario);
            let pago = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(&mut scenario));
            galeria_micro_poemas::publicar_poema(&mut galeria, pago, b"Temporal", ts::ctx(&mut scenario));
            ts::return_shared(galeria);
        };
        ts::next_tx(&mut scenario, USER1);
        {
            let poema = ts::take_from_sender<MicroPoema>(&scenario);
            galeria_micro_poemas::eliminar_poema(poema, ts::ctx(&mut scenario));
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 1)]
    fun test_texto_muy_largo() {
        let mut scenario = ts::begin(ADMIN);
        {
            galeria_micro_poemas::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, USER1);
        {
            let mut galeria = ts::take_shared<Galeria>(&scenario);
            let pago = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(&mut scenario));
            let mut texto_largo = b"";
            let mut i = 0;
            while (i < 300) {
                texto_largo.push_back(65);
                i = i + 1;
            };
            galeria_micro_poemas::publicar_poema(&mut galeria, pago, texto_largo, ts::ctx(&mut scenario));
            ts::return_shared(galeria);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 2)]
    fun test_pago_insuficiente() {
        let mut scenario = ts::begin(ADMIN);
        {
            galeria_micro_poemas::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, USER1);
        {
            let mut galeria = ts::take_shared<Galeria>(&scenario);
            let pago = coin::mint_for_testing<SUI>(50_000_000, ts::ctx(&mut scenario));
            galeria_micro_poemas::publicar_poema(&mut galeria, pago, b"Poema", ts::ctx(&mut scenario));
            ts::return_shared(galeria);
        };
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 3)]
    fun test_eliminar_poema_ajeno() {
        let mut scenario = ts::begin(ADMIN);
        {
            galeria_micro_poemas::init_for_testing(ts::ctx(&mut scenario));
        };
        ts::next_tx(&mut scenario, USER1);
        {
            let mut galeria = ts::take_shared<Galeria>(&scenario);
            let pago = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(&mut scenario));
            galeria_micro_poemas::publicar_poema(&mut galeria, pago, b"Poema de USER1", ts::ctx(&mut scenario));
            ts::return_shared(galeria);
        };
        ts::next_tx(&mut scenario, USER2);
        {
            let poema = ts::take_from_address<MicroPoema>(&scenario, USER1);
            galeria_micro_poemas::eliminar_poema(poema, ts::ctx(&mut scenario));
        };
        ts::end(scenario);
    }
}
