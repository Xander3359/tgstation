import React, {
  Component,
  CSSProperties,
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  Box,
  Button,
  Dimmer,
  Image,
  NoticeBox,
  Stack,
  Tabs,
  TimeDisplay,
} from 'tgui-core/components';
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';

import { Window } from '../layouts';
import { GenericUplink, Item } from './Uplink/GenericUplink';
import { ItemExtraData, Uplink, UplinkData, UplinkState } from './Uplink';
import '../styles/interfaces/ContractorUplink.scss';

type ContractorUplinkData = UplinkData & {
  bounty_targets: BountyTargets[];
  // low of high-to-low range for bounty payouts
  high_bounty: number;
  low_bounty: number;
  allCategories: string[];
  contract_refresh_time: number;
};

type TabViewProps = ContractorUplinkData & {
  items: ItemExtraData[];
  currentTab: number;
  setTab: (tab: number) => void;
};

type PrimaryObjectiveMenuProps = {
  bounty_targets: BountyTargets[];
  high_bounty: number;
  low_bounty: number;
  refresh_time: number;
};

type BountyTargets = {
  name: string;
  location: string;
  bounty_reward: number;
  mugshot_icon: string;
};

type Tab = {
  title: string;
  content: React.ReactNode;
  onSelect?: () => void;
};

export class ContractorUplink extends Uplink {
  render() {
    const { data } = useBackend<ContractorUplinkData>();
    const { shop_locked } = data;
    const { allCategories, currentTab } = this.state as UplinkState;
    const setTab = (tab: number) => {
      this.setState({ currentTab: tab });
    };
    const items = this.uplinkItems();
    return (
      <Window width={700} height={600} theme="contractor">
        <div>
          <Window.Content>
            <Stack fill vertical>
              <Stack.Item grow>
                <>
                  <TabView
                    {...data}
                    allCategories={allCategories}
                    currentTab={currentTab}
                    setTab={setTab}
                    items={items}
                  />
                  {(shop_locked && !data.debug && (
                    <Dimmer>
                      <Box
                        color="red"
                        fontFamily={'Bahnschrift'}
                        fontSize={3}
                        align={'top'}
                        as="span"
                      >
                        SHOP LOCKED
                      </Box>
                    </Dimmer>
                  )) ||
                    null}
                </>
              </Stack.Item>
            </Stack>
          </Window.Content>
        </div>
      </Window>
    );
  }
}

let loadedMugshots = false;

function TabView(props: TabViewProps) {
  const { act } = useBackend();
  const {
    telecrystals,
    allCategories,
    currentTab,
    setTab,
    items,
    bounty_targets,
    high_bounty,
    low_bounty,
    contract_refresh_time,
  } = props;

  const tabs: Tab[] = [
    {
      title: 'Mission Info',
      content: <MissionInfo />,
    },
    {
      title: 'Bounty Targets',
      content: (
        <BountyTargets
          bounty_targets={bounty_targets}
          high_bounty={high_bounty}
          low_bounty={low_bounty}
          refresh_time={contract_refresh_time}
        />
      ),
      onSelect: () => act('show_mugshots'),
    },
    {
      title: 'Marketplace',
      content: (
        <GenericUplink
          currency={`${telecrystals} Coins`}
          categories={allCategories}
          items={items}
          handleBuy={(item: ItemExtraData) => {
            if (!item.extraData?.ref) {
              act('buy', { path: item.id });
            } else {
              act('buy', { ref: item.extraData.ref });
            }
          }}
        />
      ),
    },
  ];

  const onTabSelect = (tab: number) => {
    setTab(tab);
    tabs[tab].onSelect?.();
  };

  return (
    <Stack vertical fill id="tabview">
      <Stack.Item>
        <Tabs fluid>
          {tabs.map((tab, index) => (
            <Tabs.Tab
              key={index}
              selected={currentTab === index}
              onClick={() => onTabSelect(index)}
            >
              {tab.title}
            </Tabs.Tab>
          ))}
        </Tabs>
      </Stack.Item>

      <Stack.Item overflowY="auto" grow>
        {tabs[currentTab].content}
      </Stack.Item>
    </Stack>
  );
}

function MissionInfo(props) {
  return <div>Mission Info</div>;
}

function BountyTargets(props: PrimaryObjectiveMenuProps) {
  const {
    bounty_targets,
    low_bounty = 0,
    high_bounty = 30,
    refresh_time = 0,
  } = props;
  const targetsElements =
    bounty_targets?.map((target, index) => (
      <Box
        key={index}
        className="ContractorBorder ContractorBlock"
        p={1}
        mb={1}
        align="center"
        style={{ display: 'flex' }}
      >
        <Box mr={2}>
          <Image
            width="128px"
            height="128px"
            src={`data:image/jpeg;base64,${target.mugshot_icon}`}
          />
        </Box>
        <Stack m={1}>
          <Box>
            <Box fontWeight="bold" fontSize={1.2} mb={0.5}>
              {target.name}
            </Box>
            <Box style={{ display: 'flex', alignItems: 'center' }}>
              Reward: {target.bounty_reward}{' '}
              <Image
                height="32px"
                src={resolveAsset(
                  `coin${BountyRange(target.bounty_reward, low_bounty, high_bounty)}.png`,
                )}
              />
            </Box>
          </Box>
          <Box>
            <h2>Choose Extraction Type</h2>
            <Button
              mb={1}
              style={{ backgroundColor: 'green' }}
              tooltip="Static location that doesn't provide additional rewards, bring your target to arrivals, departures, solar arrays or lavaland to extract your target."
            >
              Safe
            </Button>
            <Button
              mb={1}
              style={{ color: 'black', backgroundColor: 'yellow' }}
              tooltip="RNG, any non secure area on the station, grants a small bonus of coins."
            >
              Unsafe
            </Button>
            <Button
              mb={1}
              style={{ backgroundColor: 'red' }}
              tooltip="Usually a highly restricted area, provides the biggest reward."
            >
              Dangerous
            </Button>
          </Box>
        </Stack>
      </Box>
    )) ?? [];

  return (
    <Box p={2} overflow="auto" height="100%">
      <Box fontSize={1.5} fontWeight="bold" mb={1}>
        Bounty Targets
      </Box>
      <TimeDisplay value={refresh_time}></TimeDisplay>

      {targetsElements.length > 0 ? (
        targetsElements
      ) : (
        <NoticeBox>No current bounty targets available.</NoticeBox>
      )}
    </Box>
  );
}

/// 1-4 range based on low and range, on whichever is closer to the high end
function BountyRange(value: number, low: number, high: number): number {
  const range = high - low;
  const normalized = (value - low) / range;
  // should never be 0
  const clamped = Math.min(1, Math.max(0, normalized));

  const tier = Math.min(4, Math.floor(clamped * 4));
  return clamp(tier, 1, 4);
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}
