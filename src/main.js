import { mount } from "svelte";
import "./app.css";
import App from "./App.svelte";

const target = document.getElementById("app");
if (!target) {
  throw new Error("DappRank: could not find #app element to mount onto");
}

const app = mount(App, { target });

export default app;
