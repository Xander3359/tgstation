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
  ByondUi,
  Dimmer,
  NoticeBox,
  Section,
  Stack,
  Tabs,
  Tooltip,
} from 'tgui-core/components';
import { fetchRetry } from 'tgui-core/http';
import type { BooleanLike } from 'tgui-core/react';
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import {
  calculateDangerLevel,
  calculateProgression,
  dangerLevelsTooltip,
} from './Uplink/calculateDangerLevel';
import { Window } from '../layouts';
import { GenericUplink, Item } from './Uplink/GenericUplink';
import { ItemExtraData, Uplink, UplinkData, UplinkState } from './Uplink';
import '../styles/interfaces/ContractorUplink.scss';

type ContractorUplinkData = UplinkData & {
  bounty_targets: BountyTargets[];
};

type TabViewProps = {
  telecrystals: number;
  allCategories: string[];
  items: ItemExtraData[];
  currentTab: number;
  setTab: (tab: number) => void;
  bountyTargets: BountyTargets[];
};

type PrimaryObjectiveMenuProps = {
  bountyTargets: BountyTargets[];
};

type BountyTargets = {
  name: string;
  location: string;
  bounty_reward: number;
  mugshot_screen: string;
};

type Tab = {
  title: string;
  content: React.ReactNode;
  onSelect?: () => void;
};

export class ContractorUplink extends Uplink {
  render() {
    const { data } = useBackend<ContractorUplinkData>();
    const { shop_locked, telecrystals, bounty_targets } = data;
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
                    telecrystals={telecrystals}
                    allCategories={allCategories}
                    items={items}
                    currentTab={currentTab}
                    setTab={setTab}
                    bountyTargets={bounty_targets}
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

function TabView(props: TabViewProps) {
  const { act } = useBackend();
  const {
    telecrystals,
    allCategories,
    currentTab,
    setTab,
    items,
    bountyTargets,
  } = props;

  const tabs: Tab[] = [
    {
      title: 'Mission Info',
      content: <MissionInfo />,
    },
    {
      title: 'Bounty Targets',
      content: <BountyTargets bountyTargets={bountyTargets} />,
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

      <Stack.Item grow>{tabs[currentTab].content}</Stack.Item>
    </Stack>
  );
}

function MissionInfo(props) {
  return <div>Mission Info</div>;
}

function BountyTargets(props: PrimaryObjectiveMenuProps) {
  const { bountyTargets } = props;
  const targetsElements =
    bountyTargets?.map((target, index) => (
      <Box
        key={index}
        className="contractor-uplink__border"
        p={1}
        mb={1}
        align="center"
        style={{ display: 'flex' }}
      >
        <Box mr={2}>
          <ByondUi
            height="128px"
            width="128px"
            params={{
              id: target.mugshot_screen,
              type: 'map',
            }}
          />
        </Box>
        <Box>
          <Box fontWeight="bold" fontSize={1.2} mb={0.5}>
            {target.name}
          </Box>
          <Box>Last Known Location: {target.location}</Box>
          <Box>Reward: {target.bounty_reward} Coins</Box>
        </Box>
      </Box>
    )) ?? [];

  return (
    <Box p={2} overflow="auto" height="100%">
      <Box fontSize={1.5} fontWeight="bold" mb={1}>
        Bounty Targets
      </Box>
      {targetsElements.length > 0 ? (
        targetsElements
      ) : (
        <NoticeBox>No current bounty targets available.</NoticeBox>
      )}
    </Box>
  );
}
