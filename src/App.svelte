<script>
    import WalletConnector from "./components/WalletConnector.svelte";
    import DappsData from "./components/DappsData.svelte";
    import DappRankList from "./components/DappRankList.svelte";
    import InvestorInsights from "./components/InvestorInsights.svelte";
    import GetDRNK from "./components/GetDRNK.svelte";
    import RegisterDapp from "./components/RegisterDapp.svelte";
    import Vote4DappModal from "./components/Vote4DappModal.svelte";
    import GetDRNKModal from "./components/GetDRNKModal.svelte";
    import RegisterDappModal from "./components/RegisterDappModal.svelte";
    import ThemeToggle from "./components/ThemeToggle.svelte";
    import { modalState, closeModal } from "./lib/modal.svelte.js";
    import { MorphIcon } from "morphicons/svelte";
    import { Menu, X } from "lucide";

    let menuOpen = $state(false);

    function toggleMenu() {
        menuOpen = !menuOpen;
    }

    function closeMenu() {
        menuOpen = false;
    }

    // Close the mobile menu whenever a modal opens (it lives behind the overlay)
    $effect(() => {
        if (modalState.active) {
            menuOpen = false;
        }
    });

    /** @param {KeyboardEvent} e */
    function handleModalKeydown(e) {
        if (e.key === "Escape") {
            closeModal();
            return;
        }
        // Trap focus inside the dialog (WCAG 2.1.2)
        if (e.key === "Tab") {
            /** @param {Element} el @returns {boolean} */
            const isDisabled = (el) => {
                if (
                    el instanceof HTMLInputElement ||
                    el instanceof HTMLButtonElement ||
                    el instanceof HTMLSelectElement ||
                    el instanceof HTMLTextAreaElement
                ) {
                    return el.disabled;
                }
                return false;
            };
            const focusables = [
                ...document.querySelectorAll(
                    ".modal-content button, .modal-content input, .modal-content a, .modal-content select",
                ),
            ].filter((el) => !isDisabled(el));
            if (focusables.length === 0) return;
            const first = /** @type {HTMLElement} */ (focusables[0]);
            const last = /** @type {HTMLElement} */ (
                focusables[focusables.length - 1]
            );
            if (e.shiftKey && document.activeElement === first) {
                e.preventDefault();
                last.focus();
            } else if (!e.shiftKey && document.activeElement === last) {
                e.preventDefault();
                first.focus();
            }
        }
    }
</script>

<a href="#main-content" class="skip-link">Skip to main content</a>

<header
    class="sticky top-0 z-100 border-b border-neon-cyan/30 bg-void/80 px-4 py-3 sm:px-6 lg:px-10"
>
    <div class="mx-auto flex max-w-350 items-center justify-between gap-3">
        <div class="flex items-center gap-3" aria-label="DappRank home">
            <svg
                class="h-8 w-8 shrink-0 text-neon-pink"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
                aria-hidden="true"
            >
                <path d="M12 2 2 7l10 5 10-5-10-5Z" />
                <path d="M2 17l10 5 10-5" />
                <path d="M2 12l10 5 10-5" />
            </svg>
            <span
                class="bg-linear-to-r from-neon-cyan to-neon-pink bg-clip-text text-2xl font-extrabold text-transparent"
            >
                DappRank
            </span>
        </div>

        <!-- Desktop controls -->
        <nav
            class="hidden flex-wrap items-center justify-end gap-2 md:flex"
            aria-label="Primary"
        >
            <GetDRNK />
            <DappsData />
            <RegisterDapp />
            <WalletConnector />
        </nav>

        <!-- Theme toggle + mobile menu toggle (always visible) -->
        <div class="flex items-center gap-2">
            <ThemeToggle />
            <button
                class="btn-icon md:hidden"
                onclick={toggleMenu}
                aria-expanded={menuOpen}
                aria-controls="mobile-menu"
                aria-label={menuOpen ? "Close menu" : "Open menu"}
            >
                <MorphIcon
                    icon={menuOpen ? X : Menu}
                    spring="snappy"
                    reducedMotion="user"
                />
            </button>
        </div>
    </div>

    <!-- Mobile controls: 2-column grid for the action buttons, wallet full-width.
         Buttons stretch to fill their cell via .mobile-menu button { width: 100% }. -->
    {#if menuOpen}
        <nav
            id="mobile-menu"
            class="mobile-menu mx-auto mt-3 grid max-w-350 grid-cols-2 gap-2 md:hidden"
            aria-label="Mobile"
        >
            <GetDRNK />
            <DappsData />
            <RegisterDapp />
            <div class="col-span-2">
                <WalletConnector />
            </div>
        </nav>
    {/if}
</header>

<main id="main-content" class="relative text-center page-gutter">
    <div class="bg-scene"></div>
    <InvestorInsights />
    <DappRankList />
</main>

{#if modalState.active}
    <!-- Rendered at the app root so no ancestor transform/filter/backdrop-filter
       can become the containing block for the fixed overlay. -->
    <div
        class="modal-overlay"
        onclick={closeModal}
        onkeydown={handleModalKeydown}
        role="presentation"
    >
        <div
            class="modal-content"
            onclick={(e) => e.stopPropagation()}
            onkeydown={handleModalKeydown}
            role="dialog"
            aria-modal="true"
            tabindex="-1"
        >
            {#if modalState.active === "vote"}
                <Vote4DappModal />
            {:else if modalState.active === "buy"}
                <GetDRNKModal />
            {:else if modalState.active === "register"}
                <RegisterDappModal />
            {/if}
        </div>
    </div>
{/if}
