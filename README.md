<div align="center">

```
┌──────────────────────────────────────────────────────────┐
│  shivank kashyap  ·  @0xfandom                           │
│  smart contract engineer  ·  defi · cross-chain · aa     │
│  4y  ·  solidity · rust · ts · go                        │
└──────────────────────────────────────────────────────────┘
```

[linkedin](https://www.linkedin.com/in/shivank11/) · [twitter](https://twitter.com/KashyapShi8464) · [medium](https://medium.com/@shivank011) · [github](https://github.com/0xfandom)

![views](https://komarev.com/ghpvc/?username=0xfandom&color=6366F1&style=flat-square&label=views)

</div>

---

### // whoami

I ship DeFi infra that has to hold up under adversarial conditions — lending markets, omnichain stablecoins, intent-based fillers, AA wallets. Solidity is home, Rust is the second language I reach for when filler or solver logic moves off-chain. The bias is settlement correctness over feature breadth: properties before mainnet, fuzz before audit, audit before launch, and a replay-protection story for every cross-chain message.

Right now I'm heads-down on UniswapX-style intent execution and the MEV plumbing around it.

### // focus

```
lending          compound/aave-style markets, isolated pools, IRM design
cross-chain      layerzero v2 OFTs, axelar GMP, lifi routing, hyperlane
intents          uniswapx fillers, mempool ingestion, off-chain matching
account abs.     erc-4337 paymasters, eip-7702 delegation
stables          CDP-backed, omnichain mint/burn over LZ
mev              private orderflow, bundle building, revm simulation
```

### // toolbelt

| layer       | what i use                                                                    |
| ----------- | ----------------------------------------------------------------------------- |
| contracts   | foundry · hardhat · slither · openzeppelin · safe · tenderly                  |
| rust        | alloy · revm · tokio · axum · serde                                           |
| ts / node   | viem · ethers · nestjs · next                                                 |
| chains      | ethereum · arbitrum · optimism · base · polygon · zksync                      |
| messaging   | layerzero · axelar · hyperlane · ccip · lifi                                  |
| standards   | erc-20/721/1155/4626 · eip-712/2535/4337/7702                                 |
| infra       | docker · k8s · postgres · redis · grafana · prometheus                        |

### // building

**[phantom-filler](https://github.com/0xfandom/phantom-filler)** &nbsp;·&nbsp; `rust` `solidity` <br>
intent execution engine. mempool + order-book ingestion, on/off-chain liquidity routing, profitable fill loop. uniswapx-compatible.

**[streampay](https://github.com/0xfandom/streampay)** &nbsp;·&nbsp; `solidity` <br>
streaming payment primitives — continuous on-chain salary and subscription flows.

**[Security-Audit-Agent](https://github.com/0xfandom/Security-Audit-Agent)** &nbsp;·&nbsp; `python` <br>
multi-agent pipeline that triages a contract repo — slither, foundry invariants, llm review, written report.

**[Block-Explorer-MCP](https://github.com/0xfandom/Block-Explorer-MCP)** &nbsp;·&nbsp; `typescript` <br>
MCP server giving llms live on-chain reads via tool calls.

**[Telegram-DevAgent](https://github.com/0xfandom/Telegram-DevAgent)** &nbsp;·&nbsp; `typescript` <br>
telegram bot that reads, edits, and PRs code through a multi-agent loop.

**[simple-DAO](https://github.com/0xfandom/simple-DAO)** &nbsp;·&nbsp; `solidity` `typescript` <br>
minimal governance reference — proposals, voting, timelocked execution.

### // track

```
2024 ─ now    zerolend         senior smart contract engineer
              ├─ designed and deployed cross-chain bridges (layerzero, axelar)
              ├─ ~35% gas reduction on core contracts vs. baseline
              ├─ shipped eip-7702 delegation for gasless / wallet-less UX
              └─ multi-chain rollouts on polygon, arbitrum, optimism

2023 ─ 2024   khalani labs     smart contract developer
              ├─ compound/aave-style lending markets + adaptive IRMs
              ├─ CDP-backed omnichain stablecoin
              ├─ interchain liquidity routing
              └─ foundry invariant + fuzz suites end-to-end

2022 ─ 2023   mindpath         smart contract developer
              ├─ AMMs, staking, oracle-priced markets
              ├─ chainlink + custom oracle adapters
              ├─ UUPS / transparent upgradeable proxies
              └─ react / web3 dashboards on top
```

### // open to

contract engagements, protocol engineering, security audits, cross-chain infra. defi-only — lending, perps/AMMs, CDP stables, account abstraction, intents. <br>
→ [linkedin/shivank11](https://www.linkedin.com/in/shivank11/)

### // audits

I take on solidity audits, threat modeling, and invariant-suite design for protocol launches. workflow is slither + foundry invariants + manual review against an explicit threat model — not a checklist pass. reach out via linkedin for scope and engagement details.

- [Security-Audit-Agent](https://github.com/0xfandom/Security-Audit-Agent) — internal automation I use to bootstrap reviews

### // upstream

```
Pablosinyores/aether          mev / arbitrage engine
```
- [#118](https://github.com/Pablosinyores/aether/pull/118) `feat(mempool)` live tracking — subscribe + decode + mev-share SSE
- [#114](https://github.com/Pablosinyores/aether/pull/114) `fix(provider)` adaptive HTTP polling for local / anvil endpoints
- [#94](https://github.com/Pablosinyores/aether/pull/94) &nbsp;`fix(ingestion)` decode uniswap v2 / sushi swap events instead of dropping
- [#88](https://github.com/Pablosinyores/aether/pull/88) &nbsp;`feat(replay)` aether-replay binary — historical block + intra-block mev detection
- [#62](https://github.com/Pablosinyores/aether/pull/62) &nbsp;`perf(detector)` parallel revm simulation with CacheDB pre-warming
- [#52](https://github.com/Pablosinyores/aether/pull/52) &nbsp;`fix(executor)` wire gas oracle and nonce manager to real RPC
- [#43](https://github.com/Pablosinyores/aether/pull/43) &nbsp;`feat(executor)` dynamic tip share based on inclusion rate

```
Gitlawb/openclaude            oss coding-agent cli
```
- [#959](https://github.com/Gitlawb/openclaude/pull/959) `fix(openai-shim)` strip `store` when baseUrl points at gemini
- [#954](https://github.com/Gitlawb/openclaude/pull/954) `fix(worktree)` surface git stderr in rev-parse failure message
- [#953](https://github.com/Gitlawb/openclaude/pull/953) `fix(model)` cap deepseek-v4-pro output at 65536
- [#952](https://github.com/Gitlawb/openclaude/pull/952) `fix(provider)` allow remote ollama without OPENAI_API_KEY
- [#857](https://github.com/Gitlawb/openclaude/pull/857) `fix(effort)` persist xhigh and send reasoning_effort on chat_completions
- [#837](https://github.com/Gitlawb/openclaude/pull/837) `feat` add OPENCLAUDE_DISABLE_TOOL_REMINDERS env var

---

<div align="center">

<sub>contracts that survive. settlement that clears. <br> built quietly, audited loudly.</sub>

</div>
