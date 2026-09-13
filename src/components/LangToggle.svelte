<script>
    import { i18n, setLocale, t } from "../lib/i18n.svelte.js";
    import { MorphIcon } from "morphicons/svelte";
    import { Globe } from "lucide";

    /** @type {{ id: "en" | "es"; label: string }[]} */
    const LOCALES = [
        { id: "en", label: "English" },
        { id: "es", label: "Español" },
    ];

    let open = $state(false);

    function toggle() {
        open = !open;
    }

    function choose(/** @type {"en" | "es"} */ id) {
        setLocale(id);
        open = false;
    }

    /** Close the menu when clicking outside the toggle. @param {MouseEvent} e */
    function handleDocClick(e) {
        const target = e.target;
        if (
            open &&
            (!(target instanceof Element) ||
                !target.closest("[data-lang-toggle]"))
        ) {
            open = false;
        }
    }

    $effect(() => {
        if (open) {
            document.addEventListener("click", handleDocClick);
            return () => document.removeEventListener("click", handleDocClick);
        }
    });
</script>

<div class="relative" data-lang-toggle>
    <button
        class="btn-icon"
        onclick={toggle}
        aria-expanded={open}
        aria-haspopup="true"
        aria-label={t("header.changeLanguage")}
        title={t("header.changeLanguage")}
    >
        <MorphIcon
            icon={Globe}
            spring="snappy"
            reducedMotion="user"
            aria-hidden="true"
        />
    </button>

    {#if open}
        <div
            class="absolute right-0 top-full z-50 mt-2 w-44 overflow-hidden rounded-lg border border-neon-cyan/40 bg-void/95 p-1 shadow-xl backdrop-blur-md"
            role="menu"
            aria-label={t("header.language")}
        >
            {#each LOCALES as loc}
                <button
                    class="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm font-medium transition-colors duration-150 {loc.id ===
                    i18n.locale
                        ? 'bg-neon-cyan/15 text-neon-cyan'
                        : 'text-ink/80 hover:bg-neon-cyan/10'}"
                    role="menuitemradio"
                    aria-checked={loc.id === i18n.locale}
                    onclick={() => choose(loc.id)}
                >
                    <span>{loc.label}</span>
                    {#if loc.id === i18n.locale}
                        <span class="ml-auto" aria-hidden="true">✓</span>
                    {/if}
                </button>
            {/each}
        </div>
    {/if}
</div>
