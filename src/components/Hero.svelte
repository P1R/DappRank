<script>
    import { t } from "../lib/i18n.svelte.js";
    import { openModal } from "../lib/modal.svelte.js";
    import { MorphIcon } from "morphicons/svelte";
    import { Wallet, Coins, Vote, Scale, Flame, Database, Plus } from "lucide";

    const STEPS = [
        { icon: Wallet, titleKey: "hero.step1Title", textKey: "hero.step1Text" },
        { icon: Coins, titleKey: "hero.step2Title", textKey: "hero.step2Text" },
        { icon: Vote, titleKey: "hero.step3Title", textKey: "hero.step3Text" },
    ];

    const WHY = [
        { icon: Scale, titleKey: "hero.why1Title", textKey: "hero.why1Text" },
        { icon: Flame, titleKey: "hero.why2Title", textKey: "hero.why2Text" },
        {
            icon: Database,
            titleKey: "hero.why3Title",
            textKey: "hero.why3Text",
        },
    ];
</script>

<section class="mx-auto mt-10 max-w-350" aria-labelledby="hero-title">
    <div class="text-center">
        <span class="neon-tag">
            <span
                class="h-1.5 w-1.5 rounded-full bg-trust-high"
                aria-hidden="true"
            ></span>
            {t("hero.badge")}
        </span>
        <h1
            id="hero-title"
            class="mt-4 text-3xl font-extrabold tracking-tight text-ink sm:text-4xl"
        >
            {t("hero.title")}
        </h1>
        <p class="mx-auto mt-3 max-w-2xl text-base opacity-80">
            {t("hero.subtitle")}
        </p>
        <div class="mt-6 flex flex-wrap items-center justify-center gap-3">
            <button class="btn-neon" onclick={() => openModal("vote")}>
                <MorphIcon icon={Vote} class="h-4 w-4" aria-hidden="true" />
                {t("action.voteNow")}
            </button>
            <button class="btn-neon-pink" onclick={() => openModal("register")}>
                <MorphIcon icon={Plus} class="h-4 w-4" aria-hidden="true" />
                {t("action.registerDapp")}
            </button>
            <a
                class="btn-neon"
                href="https://github.com/P1R/DappRank/blob/main/WP.md"
                target="_blank"
                rel="noreferrer"
            >
                {t("action.readWhitepaper")}
            </a>
        </div>
    </div>

    <!-- How it works -->
    <div class="mt-12">
        <h2 class="text-center text-xl font-bold text-neon-cyan">
            {t("hero.howTitle")}
        </h2>
        <ol class="mt-6 grid gap-4 md:grid-cols-3">
            {#each STEPS as step, i}
                <li class="card p-5 text-left">
                    <div
                        class="flex h-9 w-9 items-center justify-center rounded-full border border-neon-cyan/40 bg-neon-cyan/10 text-sm font-bold tabular-nums text-neon-cyan"
                        aria-hidden="true"
                    >
                        {i + 1}
                    </div>
                    <h3 class="mt-3 font-semibold text-ink">
                        {t(step.titleKey)}
                    </h3>
                    <p class="mt-1 text-sm opacity-70">{t(step.textKey)}</p>
                </li>
            {/each}
        </ol>
    </div>

    <!-- Why DappRank -->
    <div class="mt-12">
        <h2 class="text-center text-xl font-bold text-neon-cyan">
            {t("hero.whyTitle")}
        </h2>
        <div class="mt-6 grid gap-4 md:grid-cols-3">
            {#each WHY as why}
                <div class="card p-5 text-left">
                    <MorphIcon
                        icon={why.icon}
                        class="h-6 w-6 text-neon-cyan"
                        aria-hidden="true"
                    />
                    <h3 class="mt-3 font-semibold text-ink">
                        {t(why.titleKey)}
                    </h3>
                    <p class="mt-1 text-sm opacity-70">{t(why.textKey)}</p>
                </div>
            {/each}
        </div>
    </div>
</section>
