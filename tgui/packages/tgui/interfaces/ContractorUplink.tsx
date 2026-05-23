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
import { GenericUplink } from './Uplink/GenericUplink';
import { ItemExtraData, Uplink, UplinkData, UplinkState } from './Uplink';
import '../styles/interfaces/ContractorUplink.scss';

enum EXTRACTION_TYPE {
  Safe = 'safe',
  Unsafe = 'unsafe',
  Dangerous = 'dangerous',
}

type ContractorUplinkData = UplinkData & {
  bounty_targets?: BountyTargets[];
  bomb_list?: BombList[];
  // low of high-to-low range for bounty payouts
  high_bounty?: number;
  low_bounty?: number;
  allCategories?: string[];
  refresh_time?: number;
};

type TabViewProps = ContractorUplinkData & {
  items: ItemExtraData[];
  currentTab: number;
  setTab: (tab: number) => void;
};

type PrimaryObjectiveMenuProps = Partial<ContractorUplinkData> & {};

type BountyTargets = {
  name?: string;
  is_head?: boolean;
  status?: string;
  target_rank?: string;
  tc_reward?: number;
  credit_reward?: number;
  payout_bonus?: number;
  wanted_message?: string;
  dropoff_location_safe?: string[];
  dropoff_location_unsafe?: string;
  dropoff_location_dangerous?: string;
  mugshot_icon?: string;
  contract_id?: string;
};

type BombList = {
  name?: string;
  active?: boolean;
};

type Tab = {
  title: string;
  content: React.ReactNode;
  onSelect?: () => void;
};

export class ContractorUplink extends Uplink {
  render() {
    const { data } = useBackend<ContractorUplinkData & UplinkData>();
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
    refresh_time,
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
          refresh_time={refresh_time}
        />
      ),
      onSelect: () => act('show_mugshots'),
    },
    {
      title: 'Marketplace',
      content: (
        <GenericUplink
          currency={`${telecrystals} Coins`}
          categories={allCategories ?? []}
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
    {
      title: 'Bomb Menu',
      content: <BombMenu />,
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

function BombMenu(props: PrimaryObjectiveMenuProps) {
  const {
    bounty_targets,
    low_bounty = 0,
    high_bounty = 30,
    refresh_time = 0,
  } = props;
  const { act } = useBackend();
  return <></>

function BountyTargets(props: PrimaryObjectiveMenuProps) {
  const {
    bounty_targets,
    low_bounty = 0,
    high_bounty = 30,
    refresh_time = 0,
  } = props;
  const { act } = useBackend();

  const extractionInfo = [
    {
      type: EXTRACTION_TYPE.Safe,
      description:
        "Static location that doesn't provide additional rewards, bring your target to arrivals, departures, solar arrays or lavaland to extract your target.",
      backgroundColor: 'green',
    },
    {
      type: EXTRACTION_TYPE.Unsafe,
      description:
        'RNG, any non secure area on the station, grants a small bonus of coins.',
      backgroundColor: 'yellow',
      color: 'black',
    },
    {
      type: EXTRACTION_TYPE.Dangerous,
      description:
        'Usually a highly restricted area, provides the biggest reward.',
      backgroundColor: 'red',
    },
  ];

  const dropoffLocationMessage = (
    target: BountyTargets,
    type: EXTRACTION_TYPE,
  ) => {
    const location = target[`dropoff_location_${type}`];
    if (!location) return 'Location: Unknown';
    const locationString = Array.isArray(location)
      ? location.join(', ')
      : location;
    return `Location: ${locationString}`;
  };

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
            {!!target.tc_reward && (
              <Box style={{ display: 'flex', alignItems: 'center' }}>
                Reward: {target.tc_reward}
                <Image
                  height="32px"
                  src={resolveAsset(
                    `coin${BountyRange(target.tc_reward, low_bounty, high_bounty)}.png`,
                  )}
                />{' '}
                and {target.credit_reward} Credits
              </Box>
            )}
          </Box>
          <Box>
            <h2>Choose Extraction Type</h2>
            {extractionInfo.map((info) => (
              <Box key={info.type} mb={1}>
                <Button
                  style={{
                    backgroundColor: info.backgroundColor,
                    color: info.color ?? 'white',
                  }}
                  onClick={() => {
                    act('call_extraction', {
                      extraction_type: info.type,
                      contract_id: target.contract_id,
                      target: target.name,
                    });
                  }}
                  tooltip={`${info.description}\n\n ${dropoffLocationMessage(target, info.type as EXTRACTION_TYPE)}`}
                >
                  {info.type.charAt(0).toUpperCase() + info.type.slice(1)}
                </Button>
              </Box>
            ))}
          </Box>
        </Stack>
      </Box>
    )) ?? [];

  return (
    <Box p={2} overflow="auto" height="100%">
      <Box fontSize={1.5} fontWeight="bold" mb={1}>
        Bounty Targets
      </Box>
      {`${refresh_time > 0 ? 'Next refresh in: ' : 'No active refresh timer.'} `}
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
